def main(verbose: ('prints more info', 'flag', 'v'), dsn: 'connection string'):
    if verbose:
        print('connecting to %s' % dsn)
    # ...

if __name__ == '__main__':
    import clap; clap.call(main)
