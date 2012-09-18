#!/usr/bin/env python

from distutils.core import setup
from pycscope import __version__

setup(name="pycscope",
      version=__version__,
      description="Generates a cscope index of Python source trees",
      author="Dean Hall",
      author_email="dwhall256\x40yahoo\x2Ecom",
      url="None",
      scripts=['pycscope.py',],
     )
