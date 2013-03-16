#!/usr/bin/env python
"""Unit tests for genFiles and parseDir.
"""

import unittest
import os
from cStringIO import StringIO
import tempfile
import shutil
import pycscope


class TestGenFiles(unittest.TestCase):

    def testgenfiles(self,):
        tmpd = tempfile.mkdtemp()
        try:
            # Create a hierarchy of files, two levels deep for coverage
            with open(os.path.join(tmpd, 'a.py'), "w") as a:
                a.write("a = 1\n")
            with open(os.path.join(tmpd, 'b'), "w") as b:
                b.write("b = 1\n")
            sd = os.path.join(tmpd, "s")
            os.mkdir(sd)
            with open(os.path.join(sd, 'c.py'), "w") as c:
                c.write("c = 1\n")
            with open(os.path.join(sd, 'd.py'), "w") as d:
                d.write("d = 1\n")
            std = os.path.join(sd, "t")
            os.mkdir(std)
            with open(os.path.join(std, 'e.py'), "w") as e:
                e.write("e = 1\n")
            with open(os.path.join(std, 'f.py'), "w") as f:
                f.write("f = 1\n")

            # Actual test
            fs = list(pycscope.genFiles(tmpd, ['a.py', 'b', "s"], True))
            self.assertEquals(fs, ['a.py', 's/t/f.py', 's/t/e.py', 's/d.py', 's/c.py'])
        finally:
            shutil.rmtree(tmpd)
