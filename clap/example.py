"""\
usage: %prog [options]
-c, --color=black: set default color
-d, --delete=: delete the given file
-a, --delete-all: delete all files
"""
from clap import OptionParser

def print_(color, txt):
    code = {'black': 30, 'red': 31}[color]
    print '\x1b[%dm%s\x1b[0m' % (code, txt)

if __name__=='__main__':
    opt = OptionParser(__doc__).parse_args()
    if not opt:
        OptionParser.exit()
    elif opt.delete_all:
        print_(opt.color, "Delete all files")
    elif opt.delete:
        print_(opt.color, "Delete the file %s" % opt.delete)
