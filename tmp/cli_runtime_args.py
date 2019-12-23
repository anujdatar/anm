# coding=utf-8

"""
run in cli with command line arguments
Usage: $ python3 cli_runtime_args.py <arg1> <arg2> <arg3> .....
Returns: nothing
Output: print args in cli.
Input:
  <arg0>: self -> name of program
  <arg1>: string or number
  <arg2>: string or number
  <arg3>: string or number

 Notes: sys.arvg: array containing args passed into python from the command line
"""

import sys

for arg in sys.argv:
    print(arg)
