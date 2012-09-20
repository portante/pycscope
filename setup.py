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

    author = "Dean Hall",
    author_email = "dwhall256\x40yahoo\x2Ecom",
    description = "Generates a cscope index of Python source trees",
    long_description = read('README'),
    license = "GPLv2",
    keywords = "pycscope cscope indexing",
    classifiers = [
        "Development Status :: 5 - Production/Stable",
        "Topic :: Utilities",
        "License :: OSI Approved :: GNU General Public License v2 (GPLv2)",
        ],
    url = "http://github.com/portante/pycscope",
)
