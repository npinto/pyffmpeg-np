from distutils.core import setup
from distutils.extension import Extension
from Cython.Distutils import build_ext

from distutils.sysconfig import get_python_lib,get_python_inc
import os.path

import sys
if sys.platform == 'win32':
	setup(
	  name = "pyffmpeg",
	  ext_modules=[ 
	    Extension("pyffmpeg", ["pyffmpeg/pyffmpeg.pyx",os.path.join(get_python_lib(),"numpy","core","include")],
		define_macros=[('EMULATE_INTTYPES', '1')],
		include_dirs=["/usr/include/ffmpeg","pyffmpeg"], 
		library_dirs=[r"\usr\lib"], 
		libraries = ["avutil-49","avformat-52","avcodec-52","swscale-0"])
	    ],
	  cmdclass = {'build_ext': build_ext}
	)
else:
	libdir = os.path.join(get_python_lib(),"numpy","core","include")
	libdir64 = libdir.replace("/lib/","/lib64")
	print libdir,libdir64
	setup(
	  name = "pyffmpeg",
	  ext_modules=[ 
	    Extension("pyffmpeg", ["pyffmpeg/pyffmpeg.pyx"],
		include_dirs=["/usr/include/ffmpeg","pyffmpeg",libdir,libdir64], 
		libraries = ["avformat","avcodec","swscale"])
	    ],
	  cmdclass = {'build_ext': build_ext},
	  version = "0.2.0",
	  author = "James Evans",
	  author_email = "jaevans@users.sf.net",
	  url = "http://www.clark-evans.com/~milamber/pyffmpeg",
	)

