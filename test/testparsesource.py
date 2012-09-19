#!/usr/bin/env python
""" Unit tests for parsing Python source into cscope index
"""

import unittest, parser
from cStringIO import StringIO
from pycscope import parseSource, Line, Symbol, NonSymbol, Mark, dumpCst


class TestMark(unittest.TestCase):
    """ Verify the Mark class.
    """

    def testConstructor(self,):
        # Verify construct accepts no parameter and only the proper marks.
        m = Mark()
        self.assertEqual('', m._test_mark)
        m = Mark('')
        self.assertEqual('', m._test_mark)
        m = Mark(None)
        self.assertEqual('', m._test_mark)
        m = Mark(Mark.FILE)
        self.assertEqual('@', m._test_mark)
        m = Mark(Mark.FUNC_DEF)
        self.assertEqual('$', m._test_mark)
        m = Mark(Mark.FUNC_CALL)
        self.assertEqual('`', m._test_mark)
        m = Mark(Mark.FUNC_END)
        self.assertEqual('}', m._test_mark)
        m = Mark(Mark.INCLUDE)
        self.assertEqual('~', m._test_mark)
        m = Mark(Mark.ASSIGN)
        self.assertEqual('=', m._test_mark)
        m = Mark(Mark.CLASS)
        self.assertEqual('c', m._test_mark)
        m = Mark(Mark.GLOBAL)
        self.assertEqual('g', m._test_mark)

        try:
            m = Mark('U')
            failed = False
        except AssertionError:
            failed = True
        self.assertTrue(failed)

    def testToString(self,):
        # Verify the string representation of a Mark is as expected
        m = Mark()
        self.assertEqual('', str(m))
        m = Mark(Mark.FILE)
        self.assertEqual('\t@', str(m))
        m = Mark(Mark.FUNC_DEF)
        self.assertEqual('\t$', str(m))
        m = Mark(Mark.FUNC_CALL)
        self.assertEqual('\t`', str(m))
        m = Mark(Mark.FUNC_END)
        self.assertEqual('\t}', str(m))
        m = Mark(Mark.INCLUDE)
        self.assertEqual('\t~', str(m))
        m = Mark(Mark.ASSIGN)
        self.assertEqual('\t=', str(m))
        m = Mark(Mark.CLASS)
        self.assertEqual('\tc', str(m))
        m = Mark(Mark.GLOBAL)
        self.assertEqual('\tg', str(m))


class TestNonSymbol(unittest.TestCase):
    """ Verify the NonSymbol class.
    """

    def testConstructorAndFormat(self,):
        ns = NonSymbol("this")
        self.assertEqual('this', ns.format())
        ns = NonSymbol('def')
        self.assertEqual('def', ns.format())

        try:
            ns = NonSymbol()
            failed = True
        except TypeError:
            failed = False
        self.assertFalse(failed, "NonSymbol object created given no parameters")

        try:
            ns = NonSymbol('')
            failed = True
        except AssertionError:
            failed = False
        self.assertFalse(failed, "NonSymbol object created for an empty string")

    def testAdd(self,):
        ns = NonSymbol("that")
        ns += NonSymbol("then")
        self.assertEqual("that then", ns.format())


class TestSymbol(unittest.TestCase):
    """ Verify the Symbol class.
    """

    def testConstructor(self,):
        # Verify the constructor properly detects bad values and stores good values.
        s = Symbol('me')
        self.assertEqual('me', s._test_name)
        self.assertEqual('', s._test_mark)

        s = Symbol('you', '$')
        self.assertEqual('you', s._test_name)
        self.assertEqual('$', s._test_mark)

        try:
            s = Symbol()
            failed = True
        except TypeError:
            failed = False
        self.assertFalse(failed, "Constructor allowed no parameters")

        try:
            s = Symbol('')
            failed = True
        except AssertionError:
            failed = False
        self.assertFalse(failed, "Constructor allowed an empty string without an function end marker")

        try:
            s = Symbol('', Mark.FUNC_END)
            failed = False
        except AssertionError:
            failed = True
        self.assertFalse(failed, "Constructor dis-allowed an empty string with an function end marker")

        try:
            s = Symbol(5)
            failed = True
        except AssertionError:
            failed = False
        self.assertFalse(failed, "Constructor allowed a non-string object")

    def testFormat(self,):
        # Verify the behavior of the formatting.
        s = Symbol('hi')
        self.assertEqual('hi', s.format())

        s = Symbol('bye', '~')
        self.assertEqual('\t~bye', s.format())


class TestLine(unittest.TestCase):
    """ Verify the Line class.
    """

    def testConstructor(self,):
        l = Line(1)
        self.assertEqual(1, l._test_lineno)
        self.assertEqual([], l._test_contents)

        l = Line(119)
        self.assertEqual(119, l._test_lineno)
        self.assertEqual([], l._test_contents)

        try:
            l = Line()
            failed = True
        except TypeError:
            failed = False
        self.assertFalse(failed, "Constructor must take one paramter")

        try:
            l = Line(1,2)
            failed = True
        except TypeError:
            failed = False
        self.assertFalse(failed, "Constructor takes only one paramter")

    def testAddAndRepr(self,):
        l = Line(113)
        l += Symbol("x", Mark.GLOBAL)
        l += NonSymbol("=")
        l += NonSymbol("5")
        self.assertEqual(["113", "\tgx", "=", "5"], l)

        l = Line(117)
        l += NonSymbol("def")
        l += Symbol("x", Mark.GLOBAL)
        l += NonSymbol("(")
        l += Symbol("y", Mark.INCLUDE)
        l += NonSymbol(")")
        self.assertEqual(["117 def ", "\tgx ", "( ", "\t~y ", ") "], l)


class TestParseSource(unittest.TestCase):

    def setUp(self,):
        self.buf = []

    def verify(self, src, exp, dump=False):
        ''' Run the verification of a source value against an expected output
            value. The values are list of strings, each string representing an
            individual line. An empty list is interpretted as an empty
            file. And empty string is interpretted as an empty line.
        '''
        # We create one long string for both source and expected values so
        # that the caller can enumerate each line without adding new lines,
        # making it easier to see what is being written.
        srcStr = "\n".join(src)
        if src:
            # Add the trailing new line only if there was something in the
            # "file".
            srcStr += "\n"
        expStr = "\n".join(exp)
        if exp:
            expStr += "\n"
        try:
            l = parseSource(srcStr, self.buf, 0, dump)
        except AssertionError as ae:
            self.fail("Internal AssertionError Encountered: %s\n"
                      "Concrete Syntax Tree:\n"
                      "%s\n"
                      % (ae, dumpCst(parser.suite(srcStr),StringIO()).getvalue()))
        self.assertEqual(l, len(self.buf))
        output = "".join(self.buf)
        self.assertEqual(output, expStr,
                         "Output not quite what was expected:\n"
                         "    out: %r\n"
                         "    exp: %r\n"
                         "Concrete Syntax Tree:\n"
                         "%s\n"
                         % (output, expStr, dumpCst(parser.suite(srcStr),StringIO()).getvalue()))

    def testEmptyCode(self,):
        # Verify we can handle an empty file.
        self.verify([], [])

    def testEmptyLines(self,):
        # Verify we can handle a file with just empty lines.
        self.verify(["", ""], [])

    def testSimpleAssignment(self,):
        # Verify we can handle simple assignment statements.
        self.verify(["a = 4",
                     "b = 6"],
                    ["1 ",
                     "\t=a",
                     " = 4",
                     "",
                     "2 ",
                     "\t=b",
                     " = 6",
                     ""])

    def testComplexAssignment(self,):
        # Verify we can handle complex assignment statements.
        self.verify(["a = 4",
                     "b = { 1, 2, (a, b), z[{'a':x[(1,)]}] }"],
                    ["1 ",
                     "\t=a",
                     " = 4",
                     "",
                     "2 ",
                     "\t=b",
                     " = { 1 , 2 , ( ",
                     "a",
                     " , ",
                     "b",
                     " ) , ",
                     "z",
                     " [ { 'a' : ",
                     "x",
                     " [ ( 1 , ) ] } ] }", 
                     ""])

    def testTrailerAssignment(self,):
        # Verify we can handle assignment statements with lhs trailers. See
        # issue #6 at http://github.com/portante/pycscope/issues/6.
        self.verify(["x.get(0, 'sth', c=True).text = 'ok'"],
                    ["1 ",
                     "\t=x",
                     " . ",
                     "\t`get",
                     " ( 0 , 'sth' , ",
                     "c",
                     " = True ) . ",
                     "text",
                     " = 'ok'",
                     ""])

    def testAugmentedAssignment(self,):
        self.verify(["a += 4",
                     "b *= 6"],
                    ["1 ",
                     "\t=a",
                     " += 4",
                     "",
                     "2 ",
                     "\t=b",
                     " *= 6",
                     ""])

    def testAugmentedAssignmentYield(self,):
        self.verify(["a += yield 4",
                     "b *= yield 6"],
                    ["1 ",
                     "\t=a",
                     " += yield 4",
                     "",
                     "2 ",
                     "\t=b",
                     " *= yield 6",
                     ""])

    def testExtendedAssignment(self,):
        self.verify(["a = \\",
                     "b = c = d = e = f = g = 6"],
                    ["1 ",
                     "\t=a",
                     " =",
                     "",
                     "2 ",
                     "\t=b",
                     " = ",
                     "\t=c",
                     " = ",
                     "\t=d",
                     " = ",
                     "\t=e",
                     " = ",
                     "\t=f",
                     " = ",
                     "\t=g",
                     " = 6",
                     ""])

    def testTupleAssignment(self,):
        self.verify(["a,b = 4, 2"],
                    ["1 ",
                     "\t=a",
                     " , ",
                     "\t=b",
                     " = 4 , 2",
                     ""])

    def testTupleAssignment1(self,):
        self.verify(["a.c,b = 4, 2"],
                    ["1 ",
                     "\t=a",
                     " . ",
                     "c",
                     " , ",
                     "\t=b",
                     " = 4 , 2",
                     ""])

    def testTupleAssignment2(self,):
        self.verify(["a[1],b = 4, 2"],
                    ["1 ",
                     "\t=a",
                     " [ 1 ] , ",
                     "\t=b",
                     " = 4 , 2",
                     ""])

    def testTupleAssignment3(self,):
        self.verify(["a[foo(a,)],b = 4, 2"],
                    ["1 ",
                     "\t=a",
                     " [ ",
                     "\t`foo",
                     " ( ",
                     "a",
                     " , ) ] , ",
                     "\t=b",
                     " = 4 , 2",
                     ""])

    def testTupleAssignment4(self,):
        self.verify(["a[k.foo(a,c)],b = 4, 2"],
                    ["1 ",
                     "\t=a",
                     " [ ",
                     "k",
                     " . ",
                     "\t`foo",
                     " ( ",
                     "a",
                     " , ",
                     "c",
                     " ) ] , ",
                     "\t=b",
                     " = 4 , 2",
                     ""])

    def testTupleAssignmentParen1(self,):
        self.verify(["(a,b) = tup"],
                    ["1 ( ",
                     "\t=a",
                     " , ",
                     "\t=b",
                     " ) = ",
                     "tup",
                     ""])

    def testTupleAssignmentParen2(self,):
        self.verify(["(a[foo(1,2)],b) = tup"],
                    ["1 ( ",
                     "\t=a",
                     " [ ",
                     "\t`foo",
                     " ( 1 , 2 ) ] , ",
                     "\t=b",
                     " ) = ",
                     "tup",
                     ""])

    def testTupleAssignmentParen3(self,):
        self.verify(["(a[z.foo(1,2)],b) = tup"],
                    ["1 ( ",
                     "\t=a",
                     " [ ",
                     "z",
                     " . ",
                     "\t`foo",
                     " ( 1 , 2 ) ] , ",
                     "\t=b",
                     " ) = ",
                     "tup",
                     ""])

    def testTupleAssignmentParen4(self,):
        self.verify(["(a[z.foo(1,(2,3),{1,{2,3}})],b) = tup"],
                    ["1 ( ",
                     "\t=a",
                     " [ ",
                     "z",
                     " . ",
                     "\t`foo",
                     " ( 1 , ( 2 , 3 ) , { 1 , { 2 , 3 } } ) ] , ",
                     "\t=b",
                     " ) = ",
                     "tup",
                     ""])

    def testListAssignmentBracket1(self,):
        self.verify(["[a,b] = tup"],
                    ["1 [ ",
                     "\t=a",
                     " , ",
                     "\t=b",
                     " ] = ",
                     "tup",
                     ""])

    def testListAssignmentBracket2(self,):
        self.verify(["[a[foo(1,2)],b] = tup"],
                    ["1 [ ",
                     "\t=a",
                     " [ ",
                     "\t`foo",
                     " ( 1 , 2 ) ] , ",
                     "\t=b",
                     " ] = ",
                     "tup",
                     ""])

    def testListAssignmentBracket3(self,):
        self.verify(["[a[z.foo(1,2)],b] = tup"],
                    ["1 [ ",
                     "\t=a",
                     " [ ",
                     "z",
                     " . ",
                     "\t`foo",
                     " ( 1 , 2 ) ] , ",
                     "\t=b",
                     " ] = ",
                     "tup",
                     ""])

    def testListAssignmentBracket4(self,):
        self.verify(["[a[z.foo(1,(2,3),{1,{2,3}})],b] = tup"],
                    ["1 [ ",
                     "\t=a",
                     " [ ",
                     "z",
                     " . ",
                     "\t`foo",
                     " ( 1 , ( 2 , 3 ) , { 1 , { 2 , 3 } } ) ] , ",
                     "\t=b",
                     " ] = ",
                     "tup",
                     ""])

    def testNestedAssignment(self,):
        # Verify we can handle crazy assignment statements.
        self.verify(["a[5] = 4",
                     "b[7].z.y.x[func(7)] = 6",
                     "b[0].q.r = 7"],
                    ["1 ",
                     "\t=a",
                     " [ 5 ] = 4",
                     "",
                     "2 ",
                     "\t=b",
                     " [ 7 ] . ",
                     "z",
                     " . ",
                     "y",
                     " . ",
                     "x",
                     " [ ",
                     "\t`func",
                     " ( 7 ) ] = 6",
                     "",
                     "3 ",
                     "\t=b",
                     " [ 0 ] . ",
                     "q",
                     " . ",
                     "r",
                     " = 7",
                     ""])

    def testSingleImport(self,):
        self.verify(["import sys"],
                    ["1 import ",
                     "\t~sys",
                     ""])

    def testSingleImportDotted(self,):
        self.verify(["import sys.mys.lys.hys"],
                    ["1 import ",
                     "\t~sys.mys.lys.hys",
                     ""])

    def testSingleImportWithName(self,):
        self.verify(["import sys as foo"],
                    ["1 import ",
                     "\t~sys",
                     " as ",
                     "foo",
                     ""])

    def testMultiImport(self,):
        self.verify(["import sys, os, time"],
                    ["1 import ",
                     "\t~sys",
                     " , ",
                     "\t~os",
                     " , ",
                     "\t~time",
                     ""])

    def testMultiImportDotted(self,):
        self.verify(["import sys.mys.lys.hys, hugh.mint, hug.a.tree"],
                    ["1 import ",
                     "\t~sys.mys.lys.hys",
                     " , ",
                     "\t~hugh.mint",
                     " , ",
                     "\t~hug.a.tree",
                     ""])

    def testMultiImportWithName(self,):
        self.verify(["import sys as bar, os as so, time.flies.like.an.arrow as emit"],
                    ["1 import ",
                     "\t~sys",
                     " as ",
                     "bar",
                     " , ",
                     "\t~os",
                     " as ",
                     "so",
                     " , ",
                     "\t~time.flies.like.an.arrow",
                     " as ",
                     "emit",
                     ""])

    def testFromImport(self,):
        self.verify(["from foo.bar import axe",
                     "from bar.foo import a,b,c"],
                    ["1 from ",
                     "\t~foo.bar",
                     " import ",
                     "axe",
                     "",
                     "2 from ",
                     "\t~bar.foo",
                     " import ",
                     "a",
                     " , ",
                     "b",
                     " , ",
                     "c",
                     ""])

    def testFuncDefNoSymbols(self,):
        # Verify the ability to handle a function definition with no symbols
        # in the body.
        self.verify(["def main():",
                     "\tpass"],
                    ["1 def ",
                     "\t$main",
                     " ( ) : ",
                     "",
                     "2 pass ",
                     "\t}",
                     ""])

    def testFuncDefEndNonSymbol(self,):
        ''' Verify the ability to handle a function definition with symbols in the body, ending with a non-symbol.
        '''
        self.verify(["def main():",
                     "\tx = 0"],
                    ["1 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "2 ",
                     "\t=x",
                     " = 0 ",
                     "\t}",
                     ""])

    def testFuncDefEndSymbol(self,):
        ''' Verify the ability to handle a function definition with symbols in the body, ending with a symbol.
        '''
        self.verify(["def main():",
                     "\tx = y"],
                    ["1 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "2 ",
                     "\t=x",
                     " = ",
                     "y",
                     " ",
                     "\t}",
                     ""])

    def testFuncDefNoSymbols(self,):
        ''' Verify the ability to handle a function definition with no symbols in the body.
        '''
        self.verify(["def main():",
                     "\tif x:\t\ty = 0",
                     "\telse:",
                     "\t\ty = 1",
                     "",
                     "",
                     "x=0"],
                    ["1 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "2 if ",
                     "x",
                     " : ",
                     "\t=y",
                     " = 0",
                     "",
                     "4 ",
                     "\t=y",
                     " = 1 ",
                     "\t}",
                     "",
                     "7 ",
                     "\t=x",
                     " = 0",
                     ""])

    def testFuncDefDecorator(self,):
        ''' Verify the ability to handle a function definition with one decorator.
        '''
        self.verify(["@bar",
                     "def main():",
                     "\tx = 0"],
                    ["1 @ ",
                     "\t`bar",
                     "",
                     "2 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "3 ",
                     "\t=x",
                     " = 0 ",
                     "\t}",
                     ""])

    def testFuncDefDecorators(self,):
        ''' Verify the ability to handle a function definition with two decorators.
        '''
        self.verify(["@bar",
                     "@foo",
                     "def main():",
                     "\tx = 0"],
                    ["1 @ ",
                     "\t`bar",
                     "",
                     "2 @ ",
                     "\t`foo",
                     "",
                     "3 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "4 ",
                     "\t=x",
                     " = 0 ",
                     "\t}",
                     ""])

    def testFuncDefDecoratorsReserved(self,):
        ''' Verify the ability to handle a function definition with decorators that are reserved.
        '''
        self.verify(["@property",
                     "@classmethod",
                     "def main():",
                     "\tx = 0"],
                    ["1 @ ",
                     "property",
                     "",
                     "2 @ ",
                     "classmethod",
                     "",
                     "3 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "4 ",
                     "\t=x",
                     " = 0 ",
                     "\t}",
                     ""])

    def testFuncDefMultipleDecorators(self,):
        ''' Verify the ability to handle a function definition with multiple decorators and dotted names.
        '''
        self.verify(["@klass.method.fire",
                     "@foo.bar",
                     "@bar.foo",
                     "def main():",
                     "\tx = 0"],
                    ["1 @ ",
                     "klass",
                     " . ",
                     "method",
                     " . ",
                     "\t`fire",
                     "",
                     "2 @ ",
                     "foo",
                     " . ",
                     "\t`bar",
                     "",
                     "3 @ ",
                     "bar",
                     " . ",
                     "\t`foo",
                     "",
                     "4 def ",
                     "\t$main",
                     " ( ) :",
                     "",
                     "5 ",
                     "\t=x",
                     " = 0 ",
                     "\t}",
                     ""])

    def testFuncCallSimple(self,):
        self.verify(["main()"],
                    ["1 ",
                     "\t`main",
                     " ( )",
                     ""])

    def testFuncCallSimpleWithArgs(self,):
        self.verify(["main(a,b=45,c)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " , ",
                     "b",
                     " = 45 , ",
                     "c",
                     " )",
                     ""])

    def testFuncCallSimpleTrailer(self,):
        self.verify(["maine.alaska()"],
                    ["1 ",
                     "maine",
                     " . ",
                     "\t`alaska",
                     " ( )",
                     ""])

    def testFuncCallSimpleTrailerWithArgs(self,):
        self.verify(["maine.alaska(4,c=3)"],
                    ["1 ",
                     "maine",
                     " . ",
                     "\t`alaska",
                     " ( 4 , ",
                     "c",
                     " = 3 )",
                     ""])

    def testFuncCallSimpleChained(self,):
        self.verify(["main()()().foo()"],
                    ["1 ",
                     "\t`main",
                     " ( ) ( ) ( ) . ",
                     "\t`foo",
                     " ( )",
                     ""])

    def testFuncCallSimpleChainedMultiple(self,):
        self.verify(["main.bar()[zoo()].a.b.c().e.f.g().foo()"],
                    ["1 ",
                     "main",
                     " . ",
                     "\t`bar",
                     " ( ) [ ",
                     "\t`zoo",
                     " ( ) ] . ",
                     "a",
                     " . ",
                     "b",
                     " . ",
                     "\t`c",
                     " ( ) . ",
                     "e",
                     " . ",
                     "f",
                     " . ",
                     "\t`g",
                     " ( ) . ",
                     "\t`foo",
                     " ( )",
                     ""])

    def testFuncCallSimpleChainedWithArgs(self,):
        self.verify(["main()()().foo(a,b=2)"],
                    ["1 ",
                     "\t`main",
                     " ( ) ( ) ( ) . ",
                     "\t`foo",
                     " ( ",
                     "a",
                     " , ",
                     "b",
                     " = 2 )",
                     ""])

    def testFuncCallWeird(self,):
        self.verify(["main[8]()"],
                    ["1 ",
                     "main",
                     " [ 8 ] ( )",
                     ""])

    def testFuncCallComplexTrailer(self,):
        self.verify(["maine.newyork.alaska[func()]()"],
                    ["1 ",
                     "maine",
                     " . ",
                     "newyork",
                     " . ",
                     "alaska",
                     " [ ",
                     "\t`func",
                     " ( ) ] ( )",
                     ""])

    def testFuncCallFunkyTrailer(self,):
        self.verify(["maine.newyork.alaska[func()].wow()"],
                    ["1 ",
                     "maine",
                     " . ",
                     "newyork",
                     " . ",
                     "alaska",
                     " [ ",
                     "\t`func",
                     " ( ) ] . ",
                     "\t`wow",
                     " ( )",
                     ""])

    def testFuncCallFunkyTrailerWithArgs(self,):
        self.verify(["maine.newyork.alaska[func()].wow(5,z=4)"],
                    ["1 ",
                     "maine",
                     " . ",
                     "newyork",
                     " . ",
                     "alaska",
                     " [ ",
                     "\t`func",
                     " ( ) ] . ",
                     "\t`wow",
                     " ( 5 , ",
                     "z",
                     " = 4 )",
                     ""])

    def testFuncCallParams(self,):
        self.verify(["main(a, b, c)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " , ",
                     "b",
                     " , ",
                     "c",
                     " )",
                     ""])

    def testFuncCallParamsLineContinuations(self,):
        self.verify(["main(a,\\",
                     "b,\\",
                     "c)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " ,",
                     "",
                     "2 ",
                     "b",
                     " ,",
                     "",
                     "3 ",
                     "c",
                     " )",
                     ""])

    def testFuncCallParamsNewlines(self,):
        self.verify(["main(a,",
                     "b,",
                     "c)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " ,",
                     "",
                     "2 ",
                     "b",
                     " ,",
                     "",
                     "3 ",
                     "c",
                     " )",
                     ""])

    def testFuncCallNamed(self,):
        self.verify(["main(a=1, b=4, c=d)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " = 1 , ",
                     "b",
                     " = 4 , ",
                     "c",
                     " = ",
                     "d",
                     " )",
                     ""])

    def testFuncCallMixedNamed(self,):
        self.verify(["main(a, b=4, c=d)"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "a",
                     " , ",
                     "b",
                     " = 4 , ",
                     "c",
                     " = ",
                     "d",
                     " )",
                     ""])

    def testFuncCallNested(self,):
        self.verify(["main(foo(1), b=bar(ext(4)))"],
                    ["1 ",
                     "\t`main",
                     " ( ",
                     "\t`foo",
                     " ( 1 ) , ",
                     "b",
                     " = ",
                     "\t`bar",
                     " ( ",
                     "\t`ext",
                     " ( 4 ) ) )",
                     ""])

    def testClass(self,):
        self.verify(["class Foo:",
                     "\tpass"],
                    ["1 class ",
                     "\tcFoo",
                     " :",
                     ""])

    def testClassAndSome(self,):
        self.verify(["class Foo:",
                     "\ta = 6",
                     "\tdef foo(a=5, b=6):",
                     "\t\tz = b",
                     "\t\ty = a",
                     "\t\tdef bar(v=7):",
                     "\t\t\tq = 0",
                     "\t\tm = bar(v=b)",
                     "\tw = foo(a=a, b=9)"],
                    ["1 class ",
                     "\tcFoo",
                     " :",
                     "",
                     "2 ",
                     "\t=a",
                     " = 6",
                     "",
                     "3 def ",
                     "\t$foo",
                     " ( ",
                     "a",
                     " = 5 , ",
                     "b",
                     " = 6 ) :",
                     "",
                     "4 ",
                     "\t=z",
                     " = ",
                     "b",
                     "",
                     "5 ",
                     "\t=y",
                     " = ",
                     "a",
                     "",
                     "6 def ",
                     "bar",
                     " ( ",
                     "v",
                     " = 7 ) :",
                     "",
                     "7 ",
                     "\t=q",
                     " = 0",
                     "",
                     "8 ",
                     "\t=m",
                     " = ",
                     "\t`bar",
                     " ( ",
                     "v",
                     " = ",
                     "b",
                     " ) ",
                     "\t}",
                     "",
                     "9 ",
                     "\t=w",
                     " = ",
                     "\t`foo",
                     " ( ",
                     "a",
                     " = ",
                     "a",
                     " , ",
                     "b",
                     " = 9 )",
                     ""])

    def testOnlyString(self,):
        self.verify(['""" This is only a string.',
                     '"""'],
                    [])

    def testStringMultiLine(self,):
        self.verify(['y = """',
                     'This is a # string.',
                     '"""'],
                    ['1 ',
                     '\t=y',
                     ' = """\\nThis is a # string.\\n"""',
                     ''])

    def testStringWithPound(self,):
        self.verify(['x = "#ffffff"'],
                    ['1 ',
                     '\t=x',
                     ' = "#ffffff"',
                     ''])

    def testLineContinuation(self,):
        self.verify(['a\\',
                     '=\\',
                     'b\\',
                     ',"""',
                     'this',
                     '"""',
                     ''],
                    ['1 ',
                     '\t=a',
                     '',
                     '3 ',
                     'b',
                     ''])

    def testMultiLineStrings(self,):
        self.verify(['a = b, """',
                     'this',
                     '"""',
                     ''],
                    ['1 ',
                     '\t=a',
                     ' = ',
                     'b',
                     ' , """\\nthis\\n"""',
                     ''])

    def testGlobal(self,):
        self.verify(['global a; global b, c, d'],
                    ['1 global ',
                     '\tga',
                     ' ; global ',
                     '\tgb',
                     ' , ',
                     '\tgc',
                     ' , ',
                     '\tgd',
                     ''])
