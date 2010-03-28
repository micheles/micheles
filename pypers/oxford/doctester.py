#!/usr/bin/env python
# Author: michele.simionato@gmail.com
"""\
Filter passing stdin through doctest. Example of usage:
$ doctester.py -v < file.txt
"""
import sys, doctest, textwrap, re, types
#import warnings;warnings.filterwarnings('ignore', category=DeprecationWarning)

# regular expressions to identify code blocks of the form
#<scriptname.py> ... </scriptname.py>
DOTNAME = r'\b[a-zA-Z_][\w\.]*', # identifier with or without dots
SCRIPT = re.compile(r'(?s)#<(%s)>(.*?)#</\1>' % DOTNAME)

# a simple utility to extract the scripts contained in the original text
def scripts(txt):
    for MO in SCRIPT.finditer(txt):
        yield MO.group(1), textwrap.dedent(MO.group(2))

# save the scripts in the current directory
def savescripts(txt):
    scriptdict = {}
    for scriptname, script in scripts(txt): # read scripts
        if scriptname not in scriptdict:
            scriptdict[scriptname] = script
        else:
            scriptdict[scriptname] += script
    for scriptname in scriptdict: # save scripts
        code = '# ' + scriptname + scriptdict[scriptname]
        print >> file(scriptname, 'w'), code

# based on a clever trick: it converts the original text into the docstring of
# the main module; works both for Python 2.3 and 2.4;
# main is needed to keep global variables in it (for instance to keep
# threads working)
def runtests(txt, verbose=False):
    savescripts(txt)
    try:
        main = __import__("_main_")
    except ImportError:
        main = types.ModuleType("__main__")
    main.__doc__ = txt
    failed, tot = doctest.testmod(main, verbose=verbose)
    doctest.master = None # cleanup the DocTestRunner
    # needed to avoid a warning in case of multiple calls of runtests
    if not verbose:
        print >> sys.stderr, "doctest: run %s tests, failed %s" % (tot, failed)
    # remove scripts
    return failed, tot

if __name__ == '__main__':
    try: set # need sets for option parsing
    except NameError: import sets; set = sets.Set # for Python 2.3
    valid_options = set("-v -h".split())
    options = set(sys.argv[1:])
    assert options < valid_options, "Unrecognized option"
    if "-h" in options: # print usage message and exit
        sys.exit(__doc__)
    runtests(sys.stdin.read(), "-v" in options)
