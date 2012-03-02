#!/usr/bin/env python
"""Unit tests for code issues found during development.
"""

import unittest
import os
import pycscope


class TestIssues(unittest.TestCase):

    def setUp(self,):
        self.idxbuf = []
        self.fnmbuf = []

    def test0018(self,):
        """ Make sure two newlines occur after a file mark when the source
            file starts with non-symbol text.
        """
        cwd = os.getcwd()
        fn = "issue0018.py"
        pycscope.parseFile(cwd, fn, self.idxbuf, self.fnmbuf)
        output = "".join(self.idxbuf)
        self.assertEqual(output, "\n"
                                 "\t@issue0018.py\n"
                                 "\n"
                                 "1 import \n"
                                 "\t~<sys\n"
                                 "\n"
                                 "\n"
                                 "3 \n"
                                 "a\n"
                                 "= 42 \n"
                                 "\n"
                                 "4 \n")

    def test0019(self,):
        """ Make sure new lines are observed when NEWLINE token doesn't exist.
        """
        src = "(a,\nb) = 4, 2\n"
        pycscope.parseSource(src, self.idxbuf)
        output = "".join(self.idxbuf)
        self.assertEqual(output, "\n"
                                 "\n"
                                 "1 ( \n"
                                 "a\n"
                                 ", \n"
                                 "\n"
                                 "2 \n"
                                 "b\n"
                                 ") = 4 , 2 \n")
