#|
The danger of benchmarks
=========================================

Benchmarks are useful in papers and blog posts, as a good trick to
attract readers, but you should never make the mistake of believing
them: as Mark Twain would say, *there are lies, damned lies, and
benchmarks*.  The problem is not only that reality is different from
benchmarks; the problem is that it is extremely easy to write a wrong
benchmark or to give a wrong interpretation of it.

In this episode I will show some of the dangers hidden under
the factorial benchmark shown in the `previous episode`_,
which on the surface looks trivial and unquestionable.
If a benchmark so simple is so delicate, I leave to your imagination
to figure out what may happen for complex benchmarks. 

The major
advantage of benchmarks is that they make clear how
wrong we are when we think that a solution is faster or slower than 
another solution.

.. _previous episode: http://www.artima.com/weblogs/viewpost.jsp?thread=239699

Beware of wasted cycles
-------------------------------------------------------------

.. image:: tartaruga.jpg

An obvious danger of benchmarks is the issue of vasted cycles.
Since usually benchmarks involve calling a function *N* times,
the time spent in the loop must be subtracted from the real
computation time. If the the computation is complex enough, usually
the time spent in the loop is negligible with respect to the time
spent in the computation. However, there are situations where this
assumption is not true.

In the factorial example you can measure the wasted cycles by subtracting
from the total time the the time spent in the loop performing no
operations (for instance by computing the factorial of zero, which
contains no multiplications). On my MacBook the total time spent
in order to compute the factorial of 7 for ten millions of times
is 3.08 seconds, whereas the time spent to compute the factorial
of zero is 0.23 seconds, i.e. fairly small but sensible. In the
case of fast operations, the time spent in the loop can change
completely the results of the benchmark.

For instance, ``add1`` it is a function which increments a number by one
and it is extremely fast. The time to sum 1+1 ten millions of times is
0.307 seconds::

 > (time (call 10000000 add1 1))
 running stats for (call 10000000 add1 1):
     no collections
     307 ms elapsed cpu time, including 0 ms collecting
     308 ms elapsed real time, including 0 ms collecting
     24 bytes allocated

If you measure the time spent in the loop and in calling the
auxiliary function ``call``, by timing a ``do-nothing`` function,
you will find a value of 0.214 seconds, i.e. 2/3 of the total
time is wasted::

 > (define (do-nothing x)  x)
 > (time (call 10000000 do-nothing 1))
 running stats for (call 10000000 do-nothing):
     no collections
     214 ms elapsed cpu time, including 0 ms collecting
     216 ms elapsed real time, including 0 ms collecting
     16 bytes allocated

Serious benchmarks must be careful in subtracting the wasted time
correctly, if it is significant. The best thing is to reduce the
wasted time. In a future episode we will consider this example again
and we will see how to remove the time wasted in ``call`` by replacing
it with a macro.

Beware of cheats
-----------------------------------------------------

.. image:: il+gatto+e+la+volpe.jpg

The issue of wasted cycles is obvious enough; on the other hand, benchmarks
are subject to less obvious effects. Here I will show a trick to improve
dramatically the performance by cheating. Let us consider the factorial
example, but using the Chicken Scheme compiler. Chicken works by
compiling Scheme code into C code which is then compiled to machine
code. Therefore, Chicken may leverage on all the dirty tricks on
the underlying C compiler. In particular, Chicken exposes a benchmark
mode where consistency checks are disabled and the ``-O3`` 
optiomization of gcc is enabled. By compiling the `factorial benchmark`_ in 
in this way you can get incredible performances::

 $  csc -Ob fact.scm # csc = Chicken Scheme Compiler
 $ ./fact 7
 ./fact 7  
 0.176 seconds elapsed
       0 seconds in (major) GC
       0 mutations
       1 minor GCs
       0 major GCs
 result:5040

We are *16* times faster than Ikarus and *173* times faster than Python!
The only disadvantage is that the script does not work: when the factorial
gets large enough (biggen than 2^31) Chicken (or better gcc) starts
yielding meaningless values. Everything is fine until ``12!``::

 $ ./fact 12 # this is smaller than 2^31, perfectly correct
   0.332 seconds elapsed
       0 seconds in (major) GC
       0 mutations
       1 minor GCs
       0 major GCs
 result:479001600

Starting from ``13!`` you get a surprise::

 $ ./fact 13 # the correct value is 6227020800, larger than 2^31
   0.352 seconds elapsed
       0 seconds in (major) GC
       0 mutations
       1 minor GCs
       0 major GCs
 result:-215430144

You see what happens when you cheat? ;)

Beware of naive optimization
-------------------------------------------------------------

.. image:: exclamation-mark.jpg

In this last section I will show a positive aspect of benchmarks:
they may be usefully employed to avoid useless optimizations.
Generally speaking, one should not try to optimize too much, since
one could waste work and get the opposite effect, especially with
modern compilers which are pretty smart.

In order to give an example, suppose we want to optimize by hand the
`factorial benchmark`_, by replacing the closure ``(call 10000000
(lambda () (fac n)))`` with the expression ``(call 10000000 fac
n)``. In theory we would expect a performance improvement since we can
skip an indirection level by calling directly ``fac`` instead of a
closure calling ``fac``.  Actually, this is what happens with: for
``n=7``, the program runs in 3.07 secondi with the closure and in 2.95
seconds without.

In Chicken - I am using Chicken 2.732 here - instead, a disaster happens
when the benchmark mode is turned on::

 $  csc -Ob fact.scm
 $ ./fact 7
    1.631 seconds elapsed
    0.011 seconds in (major) GC
        0 mutations
     1881 minor GCs
       23 major GCs
 result:5040

The program is nearly ten times slower! All the time is spent in
the garbage collector. Notice that this behavior is proper of
the benchmark mode: by compiling with the default options you
will not see significant differences in the execution time,
even if they are in any case much larger (7.07 seconds with
the closure versus 6.88 seconds without). In other words, with
the default option to use the closure has a little penalty, as
you would expect, but in benchmark mode the closure improves the
performance by ten times! I asked for an explation to Chicken's author, 
Felix Winkelmann, and here is what he said:

*In the first case, the compiler can see that all references to fac
are call sites: the value of "fac" is only used in positions where
the compiler can be absolutely sure it is a call. In the second case
the value of fac is passed to "call" (and the compiler is not clever
enough to trace the value through the execution of "call" - this
would need flow analysis). So in the first case, a specialized
representation of fac can be used ("direct" lambdas, i.e. direct-style
calls which are very fast).*

*Compiling with "-debug o" and/or "-debug 7" can also be very instructive.*

That should make clear that benchmarks are extremely delicate beasts,
where (apparently) insignificant changes may completely change the
numbers you get. So, beware of benchmarks, unless you are a compiler
expert (and in that case you must be twice as careful! ;)

.. _factorial benchmark: http://www.phyast.pitt.edu/~micheles/scheme/fact.scm

Recursion vs iteration
---------------------------------------------------------

Usually imperative languages do not support recursion too well, in the
sense that they may have a *recursion limit*, as well as inefficiencies
in the management of the stack. In such a languages it is often convenient
to convert ricorsive problems into iterative problems.
To this aim, it is convenient to rewrite first the recursive problem
in tail call form, possibly by adding auxiliary variables working as
accumulators. At this point, the rewritin as a ``while`` loop is trivial.
For instance, implementing the factorial iteratively in Python has
serious advantages: if you run the script

::

 # fact_it.py
 import sys, timeit

 def fact(x):
     acc = 1
     while x > 0:
         acc *= x
         x -= 1
     return acc

 if __name__ == '__main__':
     n = int(sys.argv[-1])
     t = timeit.Timer('fact(%d)' % n, 'from fact_it import fact')
     print t.repeat(1, number=10000000)
     print fact(n)

you will see a speed-up of circa 50% with respect to the recursive
version for "small" numbers. Alternatively, you can get an iterative
version of the factorial as ``reduce(operator.mul, range(1, n+1)``.
This was suggested by Miki Tebeka in a comment to the previous episode
and also gives a sensible speedup. However notice that ``reduce`` is not
considered Pythonic and that Guido removed it from the builtins in 
Python 3.0 - you can find it in ``functools`` now.

If you execute the equivalent Scheme code,

::

 (import (rnrs) (only (ikarus) time) (only (repeat) call))

 (define (fac x acc)
   (if (= x 0) acc
       (fac (- x 1) (* x acc))))

 (define n
   (string->number (car (reverse (command-line)))))

 (time (call 10000000 (lambda () (fac n 1))))
 (display "result:") (display (fac n 1)) (newline)

you will discover that it is slightly *slower* than the non tail-call
version (the tail-call requires less memory to run, anyway).
In any case we are an order of magnituder over Python efficiency.
If we consider benchmarks strongly dependent on function call
efficiency, like the `Fibonacci benchmark`_ of Antonio Cangiano,
the difference between Python and Scheme is even greater: on my
tests Ikarus is *thirty* times faster than Python. Other implementations
of Scheme or other functional languages (ML, Haskell) can be even faster
(I tried the SML/NJ implementation, which is *forty* times faster
than Python 2.5). Of course those benchmarks have no meaning.
With benchmarks one can prove that Python is faster than Python is
faster than Fortran and C++ in matrix computations. If you do not believe
it, please read this_ ;) 

.. _this: http://matrixprogramming.com/MatrixMultiply/
.. _Fibonacci benchmark: http://antoniocangiano.com/2007/11/28/holy-shmoly-ruby-19-smokes-python-away/

That's all folks, see you next episode!
|#