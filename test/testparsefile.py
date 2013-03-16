#!/usr/bin/env python
"""Unit tests for parseFile.
"""

import unittest
import os
import pycscope
import sys

if sys.hexversion < 0x03000000:
    ellipsis_str = ". . ."
else:
    ellipsis_str = "..."


class TestParseFile(unittest.TestCase):

    def setUp(self,):
        self.buf = []
        self.fnbuf = []
        self.maxDiff = None

    def testioerrors(self,):
        cwd = os.getcwd()
        fn = "_does_not_exist_.py"
        l = pycscope.parseFile(cwd, fn, self.buf, 0, self.fnbuf)
        self.assertEqual(l, 0)

    def testbadsyntax(self,):
        cwd = os.getcwd()
        fn = "badsyntax.py"
        try:
            l = pycscope.parseFile(cwd, fn, self.buf, 0, self.fnbuf)
        except SyntaxError as e:
            self.assertEquals(os.path.join(cwd, fn), e.filename)
        else:
            self.fail("Expected a syntax error.")
