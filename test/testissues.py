#!/usr/bin/env python
"""Unit tests for code issues found during development.
"""

import unittest
import os
import pycscope


class TestIssues(unittest.TestCase):

    def setUp(self,):
        self.buf = []
        self.fnbuf = []


    def test0018(self,):
        """ Make sure two newlines occur after a file mark
            when the source file starts with non-symbol text.
        """
        cwd = os.getcwd()
        fn = "issue0018.py"
        l = pycscope.parseFile(cwd, fn, self.buf, 0, self.fnbuf)
        self.assertEqual(l, len(self.buf))
        output = "".join(self.buf)
        self.assertEqual(output, "\n"
                                 "\t@issue0018.py\n"
                                 "\n"
                                 "1 import \n"
                                 "\t~sys\n"
                                 "\n"
                                 "3 \n"
                                 "\t=a\n"
                                 " = 42\n"
                                 "\n")


    def test0019(self,):
        """ Make sure new lines are observed 
            when NEWLINE token doesn't exist.
        """
        src = "(a,\nb,) = 4, 2\n"
        l = pycscope.parseSource(src, self.buf, 0)
        self.assertEqual(l, len(self.buf))
        output = "".join(self.buf)
        self.assertEqual(output, "1 ( \n"
                                 "\t=a\n"
                                 " ,\n"
                                 "\n"
                                 "2 \n"
                                 "\t=b\n"
                                 " , ) = 4 , 2\n"
                                 "\n")
