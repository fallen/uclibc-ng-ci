#!/usr/bin/env python3

import sys
import time

logged_in = False

def send(cmd, inpipe):
    print("< {}".format(cmd), end='')
    inpipe.write(cmd)
    inpipe.flush()

def handle(line, inpipe):
    global logged_in
    print("> {}".format(line), end='', flush=True)
    if not logged_in and line.startswith('Welcome to Buildroot'):
        time.sleep(1)
        print("we got the prompt!")
        send("root\n", inpipe)
        logged_in = True
        time.sleep(5)
        send("cd /usr/lib/uclibc-ng-test/test\n", inpipe)
        send("sh uclibcng-testrunner.sh\n", inpipe)
    if logged_in and line.contains('Total passed:'):
        print("uClibc-ng testsuite run is over, exiting.")
        sys.exit(0)



def main():
    pipename = sys.argv[1]
    outpipename = pipename + ".out"
    inpipename = pipename + ".in"
    inpipe = open(inpipename, "w")
    with open(outpipename, "r", 1) as p:
        not_eof = True
        while not_eof:
            line = p.readline()
            if line == '':
                not_eof = False
                print("end of file!")
            handle(line, inpipe)

if __name__ == "__main__":
    main()
