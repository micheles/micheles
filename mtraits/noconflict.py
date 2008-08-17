"""
An helper module for meta-type conflict resolution
"""

import inspect, types

memoized_metaclasses_map = {}

def skip_redundant(iterable, skipset=None):
   "Redundant items are repeated items or items in the original skipset."
   if skipset is None: skipset = set()
   for item in iterable:
       if item not in skipset:
           skipset.add(item)
           yield item

def remove_redundant(metaclasses):
   skipset = set([types.ClassType])
   for meta in metaclasses: # determines the metaclasses to be skipped
       skipset.update(inspect.getmro(meta)[1:])
   return tuple(skip_redundant(metaclasses, skipset))

# make tuple of needed metaclasses in specified priority order
def get_noconflict_metaclass(bases, left_metas, right_metas):
    metas = left_metas + tuple(map(type, bases)) + right_metas
    needed_metas = remove_redundant(metas)

    # return existing confict-solving meta, if any
    if needed_metas in memoized_metaclasses_map:
        return memoized_metaclasses_map[needed_metas]
    # nope: compute, memoize and return needed conflict-solving meta
    elif not needed_metas: # wee, a trivial case, happy us
        meta = type
    elif len(needed_metas) == 1: # another trivial case
        meta = needed_metas[0]
    # check for recursion, can happen i.e. for Zope ExtensionClasses
    elif needed_metas == bases: 
        raise TypeError("Incompatible root metatypes", needed_metas)
    else: # gotta work ...
        metaname = '_' + ''.join(m.__name__ for m in needed_metas)
        meta = classmaker()(metaname, needed_metas, {})
    memoized_metaclasses_map[needed_metas] = meta
    return meta

# recursive builder used in conjunction with get_noconflict_metaclass
def classmaker(left_metas=(), right_metas=()):
    def make_class(name, bases, adict):
        metaclass = get_noconflict_metaclass(bases, left_metas, right_metas)
        return metaclass(name, bases, adict)
    return make_class
