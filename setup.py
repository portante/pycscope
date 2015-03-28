#!/usr/bin/env python

import os
from setuptools import setup, find_packages
from pycscope import __version__

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup (
    name = "pycscope",
    version = __version__,
    packages = [ "pycscope", ],
    entry_points = {
        'console_scripts': [
            'pycscope = pycscope:main',
            ],
        },

    author = "Peter Portante",
    author_email = "peter\x2Ea\x2Eportante\x40gmail\x2Ecom",
    description = "Generates a cscope index of Python source trees",
    long_description = read('README.md'),
    license = "GPLv2",
    keywords = "pycscope cscope indexing",
    classifiers = [
        "Development Status :: 5 - Production/Stable",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        "Programming Language :: Python :: 2.7",
        "Programming Language :: Python :: 3",
        "Topic :: Software Development",
        "Topic :: Text Editors",
        "Topic :: Text Editors :: Integrated Development Environments (IDE)",
        "Topic :: Text Editors :: Text Processing",
        "Topic :: Text Processing :: Indexing",
        "Topic :: Utilities",
        ],
    url = "http://github.com/portante/pycscope",
)
