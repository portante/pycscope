#!/usr/bin/env python
"""Unit tests for work.
"""

import unittest
import os
from cStringIO import StringIO
import tempfile
import shutil
import pycscope


class TestWork(unittest.TestCase):

    def testwork(self,):
        tmpd = tempfile.mkdtemp()
        try:
            # Create three sample files, a, b and s, where a and b are
            # syntactically correct and s is not.
            with open(os.path.join(tmpd, 'a'), "w") as a:
                a.write("a = 1\n")
            with open(os.path.join(tmpd, 'b'), "w") as b:
                b.write("b = 1\n")
            with open(os.path.join(tmpd, 's'), "w") as s:
                s.write("a a (b)\n")

            # Actual test
            ibuf, fbuf = pycscope.work(tmpd, ['a', 's', 'b'], False)
            self.assertEquals(ibuf, ['\n\t@a\n\n', '1 \n\t=a\n = 1\n\n', '\n\t@s\n\n', '\n\t@b\n\n', '1 \n\t=b\n = 1\n\n'])
            self.assertEquals(fbuf, ['a', 's', 'b'])
        finally:
            shutil.rmtree(tmpd)
