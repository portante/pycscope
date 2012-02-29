#!/usr/bin/env python
""" Unit tests for parsing Python source into cscope index
"""

import unittest
import pycscope


class TestParseSource(unittest.TestCase):

    def setUp(self,):
        self.buf = []


    def testEmptyCode(self,):
        src = ""
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n")


    def testEmptyLine(self,):
        src = "\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n")


    def testSimpleAssignment(self,):
        src = "a = 4\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 \na\n= 4 \n")


    def testTupleAssignment(self,):
        src = "a,b = 4, 2\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 \n"
                                 "a\n, \n"
                                 "b\n= 4 , 2 \n")


    def testSingleImport(self,):
        src = "import sys\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 import \n"
                                 "\t~<sys\n\n")


    def testMultiImport(self,):
        src = "import sys, os, time\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 import \n"
                                 "\t~<sys\n, \n"
                                 "\t~<os\n, \n"
                                 "\t~<time\n\n")


    def testFuncDef(self,):
        """Also tests FUNC_END."""
        src = "def main():\n\tpass\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 def \n"
                                 "\t$main\n( ) : \n\n"
                                 "2 pass \n\n"
                                 "2 \n\t}\n\n")


    def testFuncCall(self,):
        src = "main()\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 \n"
                                 "\t`main\n( ) \n")


    def testClass(self,):
        src = "class Foo:\n\tpass\n"
        pycscope.parseSource(src, self.buf)
        output = "".join(self.buf)
        self.assertEqual(output, "\n\n1 class \n"
                                 "\tcFoo\n"
                                 ": \n\n"
                                 "2 pass \n")
