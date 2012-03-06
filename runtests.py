#!/usr/bin/env python


import os
import unittest

from test import testissues
from test import testparsesource
from test import testimports


def main():
    testcases = (testissues.TestIssues,
                 testimports.TestImports,
                 testparsesource.TestParseSource,
                 testparsesource.TestSymbol,
                 testparsesource.TestNonSymbol,
                 testparsesource.TestMark,
                )
    suite = unittest.TestSuite(map(unittest.makeSuite, testcases))

    tr = unittest.TextTestRunner()
    tr.run(suite)


if __name__ == "__main__":
    os.chdir("test")
    main()
