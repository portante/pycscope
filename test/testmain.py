#!/usr/bin/env python
"""Unit tests for main.
"""

import unittest
import os
import tempfile
import shutil
import pycscope


class TestMain(unittest.TestCase):

    def setUp(self,):
        self.orig_wd = os.getcwd()
        self.tmpd = tempfile.mkdtemp()
        os.chdir(self.tmpd)

    def tearDown(self,):
        os.chdir(self.orig_wd)
        self.orig_wd = None
        shutil.rmtree(self.tmpd)
        self.tmpd = None
        pycscope.strings_as_symbols = False

    def testmainopterr(self,):
        ret = pycscope.main()
        assert 2 == ret, "Expected 2, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert [] == ret, "Expected [], got %r" % ret

    def testmainbadargs(self,):
        ret = pycscope.main(['arg0', '-X'])
        assert 2 == ret, "Expected 2, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert [] == ret, "Expected [], got %r" % ret

    def testmainnoargs(self,):
        ret = pycscope.main(['arg0',])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert ['cscope.out',] == ret, "Expected ['cscope.out'], got %r" % ret

    def testmaindashV(self,):
        ret = pycscope.main(['arg0', '-V'])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert [] == ret, "Expected [], got %r" % ret

    def testmaindashD(self,):
        ret = pycscope.main(['arg0', '-D'])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert ['cscope.out',] == ret, "Expected ['cscope.out'], got %r" % ret

    def testmaindashf(self,):
        ret = pycscope.main(['arg0', '-f', 'pycscope.out'])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = os.listdir(self.tmpd)
        assert ['pycscope.out',] == ret, "Expected ['pycscope.out'], got %r" % ret

    def testmaindashi(self,):
        with open(os.path.join(self.tmpd, 'a.py'), 'w') as a:
            a.write('a = "b"\n')
        with open(os.path.join(self.tmpd, 'b.py'), 'w') as b:
            b.write('b = 2\n')
        with open(os.path.join(self.tmpd, 'filelist'), 'w') as f:
            f.write('b.py\na.py\n')
        ret = pycscope.main(['arg0', '-i', 'filelist'])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = sorted(os.listdir(self.tmpd))
        expf = ['a.py', 'b.py', 'cscope.out', 'filelist']
        assert expf == ret, "Expected %r, got %r" % (expf, ret)
        with open(os.path.join(self.tmpd, 'cscope.out'), 'r') as c:
            contents = c.read()
        # Expected index contents
        eindexbuff = '\n\t@b.py\n\n1 \n\t=b\n = 2\n\n\n\t@a.py\n\n1 \n\t=a\n = "b"\n\n\n\t@'
        # Expected trailer contents
        etrailerbuff = '\n1\n.\n0\n2\n10\nb.py\na.py\n'
        # Resolve symlinks from the test environment path to mimic the normal
        # behavior.
        fpath = os.path.realpath(self.tmpd)
        # Finally, reconstruct the expected contents.
        econtents = 'cscope 15 %s -c %010d%s%s' % (fpath, len(fpath) + 25 + len(eindexbuff), eindexbuff, etrailerbuff)
        assert econtents == contents, "Expected %r, got %r" % (econtents, contents)

    def testmaindashRdashS(self,):
        with open(os.path.join(self.tmpd, 'a.py'), 'w') as a:
            a.write('a = 1\n')
        with open(os.path.join(self.tmpd, 'b.py'), 'w') as b:
            b.write('b = 2\n')
        tmpdd = os.path.join(self.tmpd, 'd')
        os.mkdir(tmpdd)
        with open(os.path.join(tmpdd, 'c.py'), 'w') as c:
            c.write('c = 3\n')
        ret = pycscope.main(['arg0', '-R', '-S', '.'])
        assert 0 == ret, "Expected 0, got %r" % ret
        ret = sorted(os.listdir(self.tmpd))
        expf = ['a.py', 'b.py', 'cscope.out', 'd']
        assert expf == ret, "Expected %r, got %r" % (expf, ret)
        with open(os.path.join(self.tmpd, 'cscope.out'), 'r') as c:
            contents = c.read()
        # Expected index contents
        eindexbuff = '\n\t@./a.py\n\n1 \n\t=a\n = 1\n\n\n\t@./b.py\n\n1 \n\t=b\n = 2\n\n\n\t@./d/c.py\n\n1 \n\t=c\n = 3\n\n\n\t@'
        # Expected trailer contents
        etrailerbuff = '\n1\n.\n0\n3\n23\n./a.py\n./b.py\n./d/c.py\n'
        # Resolve symlinks from the test environment path to mimic the normal
        # behavior.
        fpath = os.path.realpath(self.tmpd)
        # Finally, reconstruct the expected contents.
        econtents = 'cscope 15 %s -c %010d%s%s' % (fpath, len(fpath) + 25 + len(eindexbuff), eindexbuff, etrailerbuff)
        assert econtents == contents, "Expected %r, got %r" % (econtents, contents)
