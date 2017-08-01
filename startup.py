#!/usr/bin/env python

import os
import sys

# Add our Virtual Environment site packages path to our system path on bootup of
# the dev server. This will allow you to install things to your local venv like
# pycrypto, etc and actually get them to be used by the dev_server since GAE
# cluster-f'd this up in so many ways.
venv = os.environ.get("VIRTUAL_ENV")
if venv:
    sys.path.insert(0, "{}/lib/python2.7/site-packages".format(venv))

from google.appengine.ext import vendor
vendor.add(venv)
print 40 * "$"
print 40 * "$"
print venv
print sys.path
print 40 * "$"
print 40 * "$"
