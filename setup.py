from distribute_setup import use_setuptools
use_setuptools()
from setuptools import setup, find_packages

import os
from distutils.extension import Extension
from Cython.Distutils import build_ext
from distutils.sysconfig import get_python_lib, get_python_inc

import numpy
libdir = numpy.get_numpy_include()

setup(
    name = "pyffmpeg",
    version = "0.2.0-np",

    ext_modules=[ 
        Extension("pyffmpeg",
                  ["pyffmpeg/pyffmpeg.pyx"],
                  include_dirs=["/usr/include/libavcodec",
                                "/usr/include/libavutil",
                                "/usr/include/libavformat",
                                "/usr/include/libswscale",
                                "/usr/include/ffmpeg",
                                "pyffmpeg",
                                libdir,
                                ],
                  libraries = ["avcodec",
                               "avutil",
                               "avformat",
                               "swscale",
                               ],
                  )
        ],
    cmdclass = {'build_ext': build_ext},

    include_package_data = True,    
    install_requires = [
        "numpy>=1.3.0",
        ],
    
)
