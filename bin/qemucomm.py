#!/usr/bin/env python3

import sys
import time
import re

from junit_xml import TestSuite, TestCase

logged_in = False
test_cases = []

def send(cmd, inpipe):
    print("< {}".format(cmd), end='')
    inpipe.write(cmd)
    inpipe.flush()

def handle(line, inpipe):
    global logged_in
    global test_cases
    print("> {}".format(line), end='', flush=True)
    if not logged_in:
        if line.startswith('Welcome to Buildroot'):
            time.sleep(1)
            print("we got the prompt!")
            send("root\n", inpipe)
            logged_in = True
            time.sleep(5)
            send("cd /usr/lib/uclibc-ng-test/test\n", inpipe)
            send("sh uclibcng-testrunner.sh\n", inpipe)
    else:
        if 'PASS ' in line:
            r = re.match("PASS (.*)", line)
            if r:
                test_name = r.group(1)
                test = TestCase(test_name, '', time.time())
                test_cases.append(test)

        if 'FAIL ' in line:
            r = re.match("FAIL (.*)", line)
            if r:
                test_name = r.group(1)
                test = TestCase(test_name, '', time.time())
                test.add_failure_info(message="FAIL")
                test_cases.append(test)

        if 'SKIP' in line:
            r = re.match("SKIP (.*)", line)
            if r:
                test_name = r.group(1)
                test = TestCase(test_name, '', time.time())
                test.add_skipped_info(message="SKIP")
                test_cases.append(test)

        if 'Total passed:' in line:
            print("uClibc-ng testsuite run is over, writing test results and exiting.")
            return False

    return True


def main():
    global test_cases
    pipename = sys.argv[1]
    test_output_file = sys.argv[2]
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
            keep_running = handle(line, inpipe)
            if not keep_running:
                break

    ts = TestSuite("uClibc-ng testsuite", test_cases)
    with open(test_output_file, "w+") as to:
        to.write(TestSuite.to_xml_string([ts]))

if __name__ == "__main__":
    main()
