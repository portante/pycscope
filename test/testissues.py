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

    def testIssue0003(self):
        """ Verify we don't have conflicting marks.
        """
        src = """
class MyClass(object):

    @property
    def get_bar(self):
        return 'foo'

    def my_method(self):
        from datetime import datetime
"""
        l = pycscope.parseSource(src, self.buf, 0)
        self.assertEqual(l, len(self.buf))
        output = "".join(self.buf)
        self.assertEqual(output, "2 class \n"
                                 "\tcMyClass\n"
                                 " ( \n"
                                 "object\n"
                                 " ) :\n"
                                 "\n"
                                 "4 @ \n"
                                 "property\n"
                                 "\n"
                                 "5 def \n"
                                 "\t$get_bar\n"
                                 " ( \n"
                                 "self\n"
                                 " ) :\n"
                                 "\n"
                                 "8 def \n"
                                 "\t$my_method\n"
                                 " ( \n"
                                 "self\n"
                                 " ) :\n"
                                 "\n"
                                 "9 from \n"
                                 "\t~datetime\n"
                                 " import \n"
                                 "datetime\n"
                                 " \n"
                                 "\t}\n"
                                 "\n")


    def testIssue0009(self):
        """ Verify dumpCst works on tuples.
        """
        try:
            from cStringIO import StringIO
        except ImportError:
            from io import StringIO
        out = StringIO()
        import parser, sys
        cst = parser.suite("import sys\na = b\n")
        pycscope.dumpCst(cst.totuple(True), out)
        output = out.getvalue()
        if sys.hexversion < 0x03000000:
            expected = "['file_input',\n ['stmt',\n  ['simple_stmt',\n   ['small_stmt',\n    ['import_stmt',\n     ['import_name',\n      ['NAME', 'import', 1],\n      ['dotted_as_names',\n       ['dotted_as_name', ['dotted_name', ['NAME', 'sys', 1]]]]]]],\n   ['NEWLINE', '', 1]]],\n ['stmt',\n  ['simple_stmt',\n   ['small_stmt',\n    ['expr_stmt',\n     ['testlist',\n      ['test',\n       ['or_test',\n        ['and_test',\n         ['not_test',\n          ['comparison',\n           ['expr',\n            ['xor_expr',\n             ['and_expr',\n              ['shift_expr',\n               ['arith_expr',\n                ['term',\n                 ['factor',\n                  ['power', ['atom', ['NAME', 'a', 2]]]]]]]]]]]]]]]],\n     ['EQUAL', '=', 2],\n     ['testlist',\n      ['test',\n       ['or_test',\n        ['and_test',\n         ['not_test',\n          ['comparison',\n           ['expr',\n            ['xor_expr',\n             ['and_expr',\n              ['shift_expr',\n               ['arith_expr',\n                ['term',\n                 ['factor',\n                  ['power', ['atom', ['NAME', 'b', 2]]]]]]]]]]]]]]]]]],\n   ['NEWLINE', '', 2]]],\n ['NEWLINE', '', 2],\n ['ENDMARKER', '', 2]]\n"
        else:
            expected = "['file_input',\n ['stmt',\n  ['simple_stmt',\n   ['small_stmt',\n    ['import_stmt',\n     ['import_name',\n      ['NAME', 'import', 1],\n      ['dotted_as_names',\n       ['dotted_as_name', ['dotted_name', ['NAME', 'sys', 1]]]]]]],\n   ['NEWLINE', '', 1]]],\n ['stmt',\n  ['simple_stmt',\n   ['small_stmt',\n    ['expr_stmt',\n     ['testlist_star_expr',\n      ['test',\n       ['or_test',\n        ['and_test',\n         ['not_test',\n          ['comparison',\n           ['expr',\n            ['xor_expr',\n             ['and_expr',\n              ['shift_expr',\n               ['arith_expr',\n                ['term',\n                 ['factor',\n                  ['power', ['atom', ['NAME', 'a', 2]]]]]]]]]]]]]]]],\n     ['EQUAL', '=', 2],\n     ['testlist_star_expr',\n      ['test',\n       ['or_test',\n        ['and_test',\n         ['not_test',\n          ['comparison',\n           ['expr',\n            ['xor_expr',\n             ['and_expr',\n              ['shift_expr',\n               ['arith_expr',\n                ['term',\n                 ['factor',\n                  ['power', ['atom', ['NAME', 'b', 2]]]]]]]]]]]]]]]]]],\n   ['NEWLINE', '', 2]]],\n ['NEWLINE', '', 2],\n ['ENDMARKER', '', 2]]\n"
        print(repr(output))
        self.assertEqual(output, expected)
