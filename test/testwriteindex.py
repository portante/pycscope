#!/usr/bin/env python
"""Unit tests for writeIndex.
"""

import unittest
from cStringIO import StringIO
import pycscope


class TestWriteIndex(unittest.TestCase):

    def testioerrors(self,):
        fout = StringIO()
        pycscope.writeIndex("/tmp/foo/bar", fout, ['mockline1','mockline2'], ["fname1","fname2"])
        self.assertEquals("cscope 15 /tmp/foo/bar -c 0000000055mockline1mockline2\n1\n.\n0\n2\n14\nfname1\nfname2\n", fout.getvalue())
