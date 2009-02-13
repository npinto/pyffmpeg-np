# pyffmpeg.pyx - read frames from video files and convert to PIL image
#
# Copyright (C) 2006-2007 James Evans <jaevans@users.sf.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307	USA

try:
	import Image
	_HAS_PIL = True
except ImportError:
	_HAS_PIL = False
	
try:
	cimport numpy
	import numpy
	_HAS_NUMPY = True
except ImportError:
	_HAS_NUMPY = False

try:
	import cairo
	_HAS_CAIRO = True
except:
	_HAS_CAIRO = False
	
if not (_HAS_PIL or _HAS_CAIRO or _HAS_NUMPY):
	raise ImportError, "No Image library available. One of PIL, Cairo, or numpy required"
	
ctypedef unsigned char uint8_t

cdef extern from "Python.h":
	ctypedef int Py_ssize_t
	
	object PyBuffer_FromMemory(void *ptr, int size)
	object PyBuffer_FromReadWriteMemory(void *ptr, Py_ssize_t size)
	
from python_string cimport PyString_FromStringAndSize
from python_mem cimport PyMem_Malloc,PyMem_Free

from ffmpeg cimport *
#from libavcodec cimport *
	
# use the new swscale interface

cdef __registered
__registered = 0

def py_av_register_all():
	if __registered:
		return
	__registered = 1
	av_register_all()

cdef AVRational AV_TIME_BASE_Q
AV_TIME_BASE_Q.num = 1
AV_TIME_BASE_Q.den = AV_TIME_BASE

cdef enum:
	IMAGE_LIBRARY_PIL = 0,
	IMAGE_LIBRARY_CAIRO = 1,
	IMAGE_LIBRARY_NUMPY = 2,
# make the formats available to Python as well
image_library_pil = IMAGE_LIBRARY_PIL
image_library_cairo = IMAGE_LIBRARY_CAIRO
image_library_numpy = IMAGE_LIBRARY_NUMPY

cdef class VideoStream:
	cdef AVFormatContext *FormatCtx
	cdef AVCodecContext *CodecCtx
	cdef AVCodec *Codec
	cdef AVPacket packet
	cdef int videoStream
	cdef AVFrame *frame
	cdef int frameno
	cdef object filename
	cdef object index
	cdef object keyframes
	cdef int image_library
	
	def __new__(self, image_library = IMAGE_LIBRARY_PIL):
		self.FormatCtx = NULL
		self.frame = avcodec_alloc_frame()
		self.frameno = 0
		self.videoStream = -1
		self.Codec = NULL
		self.filename = None
		self.index = None
		self.keyframes = None
		self.SetImageLibrary(image_library)

	def dump(self):
		dump_format(self.FormatCtx,0,self.filename,0)

	def open(self,char *filename):
		cdef AVFormatContext *pFormatCtx
		cdef int ret
		cdef int i

		py_av_register_all()
		ret = av_open_input_file(&self.FormatCtx,filename,NULL,0,NULL)
		pFormatCtx = <AVFormatContext *>self.FormatCtx
		if ret != 0:
			raise IOError("Unable to open file %s" % filename)

		ret = av_find_stream_info(pFormatCtx)
		if ret < 0:
			raise IOError("Unable to find stream info: %d" % ret)

		self.videoStream = -1
		for i from 0 <= i < pFormatCtx.nb_streams:
			if pFormatCtx.streams[i].codec.codec_type == CODEC_TYPE_VIDEO:
				self.videoStream = i
				break
		if self.videoStream == -1:
			raise IOError("Unable to find video stream")

		self.CodecCtx = pFormatCtx.streams[self.videoStream].codec
		self.Codec = avcodec_find_decoder(self.CodecCtx.codec_id)

		if self.Codec == NULL:
			raise IOError("Unable to get decoder")

		# Inform the codec that we can handle truncated bitstreams -- i.e.,
		# bitstreams where frame boundaries can fall in the middle of packets
		if self.Codec.capabilities & CODEC_CAP_TRUNCATED:
			self.CodecCtx.flags = self.CodecCtx.flags & CODEC_FLAG_TRUNCATED
		# Open codec
		ret = avcodec_open(self.CodecCtx, self.Codec)
		if ret < 0:
			raise IOError("Unable to open codec")
		self.filename = filename
		
	def SetImageLibrary(self,new_library):
		if new_library == IMAGE_LIBRARY_PIL:
			if not _HAS_PIL:
				raise ValueError, "PIL format requested, but PIL not availble"
		elif new_library == IMAGE_LIBRARY_CAIRO:
			if not _HAS_CAIRO:
				raise ValueError, "Cairo format requested, but pycairo not available"
		elif new_library == IMAGE_LIBRARY_NUMPY:
			if not _HAS_NUMPY:
				raise ValueError, "Numpy format requested, but numpy not available"
		else:
			raise ValueError, "Unknown image format requested"
		self.image_library = new_library
		
	cdef AVFrame *ConvertToRGBA(self,AVFrame *frame,AVCodecContext *pCodecCtx):
		cdef AVFrame *pFrameRGBA
		cdef int numBytes
		cdef unsigned char *rgb_buffer
		cdef int width,height
		cdef SwsContext *scale_context
		
		pFrameRGBA = avcodec_alloc_frame()
		if pFrameRGBA == NULL:
			raise MemoryError("Unable to allocate RGB Frame")

		width = pCodecCtx.width
		height = pCodecCtx.height
		# Determine required buffer size and allocate buffer
		numBytes = avpicture_get_size(PIX_FMT_RGB32, width, height)
		
		# Hrm, how do I figure out when to release the old one....
		rgb_buffer = <unsigned char *>PyMem_Malloc(numBytes)
		avpicture_fill(<AVPicture *>pFrameRGBA, rgb_buffer, PIX_FMT_RGB32, width, height)

		scale_context = sws_getContext(pCodecCtx.width, pCodecCtx.height, pCodecCtx.pix_fmt, width,height,PIX_FMT_RGB32,SWS_BICUBIC,NULL,NULL,NULL)
		if scale_context == NULL:
			av_free(pFrameRGBA)
			raise MemoryError, "Unable to allocate SwsContext"
			
		sws_scale(scale_context,<uint8_t**>frame.data,frame.linesize,0,pCodecCtx.height,<uint8_t **>pFrameRGBA.data,<int *>pFrameRGBA.linesize)
		sws_freeContext(scale_context)
		return pFrameRGBA

	cdef AVFrame *ConvertToRGB24(self,AVFrame *frame,AVCodecContext *pCodecCtx):
		cdef AVFrame *pFrameRGB24
		cdef int numBytes
		cdef unsigned char *rgb_buffer
		cdef int width,height
		cdef SwsContext *scale_context

		pFrameRGB24 = avcodec_alloc_frame()
		if pFrameRGB24 == NULL:
			raise MemoryError("Unable to allocate RGB Frame")

		width = pCodecCtx.width
		height = pCodecCtx.height
		# Determine required buffer size and allocate buffer
		numBytes=avpicture_get_size(PIX_FMT_RGB24, width,height)
		# Hrm, how do I figure out how to release the old one....
		rgb_buffer = <unsigned char *>PyMem_Malloc(numBytes)
		avpicture_fill(<AVPicture *>pFrameRGB24, rgb_buffer, PIX_FMT_RGB24,
				width, height)

		scale_context = sws_getContext(pCodecCtx.width, pCodecCtx.height, pCodecCtx.pix_fmt, width,height,PIX_FMT_RGB24,SWS_BICUBIC,NULL,NULL,NULL)
		if scale_context == NULL:
			av_free(pFrameRGB24)
			raise MemoryError, "Unable to allocate SwsContext"
			
		sws_scale(scale_context,<uint8_t**>frame.data,frame.linesize,0,pCodecCtx.height,<uint8_t **>pFrameRGB24.data,<int *>pFrameRGB24.linesize)
		sws_freeContext(scale_context)
		return pFrameRGB24

	def SaveFrame(self):
		cdef int i
		cdef void *p
		cdef AVFrame *pFrameRGB
		cdef int width,height

		width = self.CodecCtx.width
		height = self.CodecCtx.height

		# I haven't figured out how to write RGBA data to an ppm file so I use a 24 bit version
		pFrameRGB = self.ConvertToRGB24(self.frame,self.CodecCtx)
		filename = "frame%04d.ppm" % self.frameno
		f = open(filename,"wb")

		f.write("P6\n%d %d\n255\n" % (width,height))
		f.flush()
		for i from 0 <= i < height:
			f.write(PyBuffer_FromMemory(pFrameRGB.data[0] + i * pFrameRGB.linesize[0],width * 3))
		f.close()
		PyMem_Free(pFrameRGB.data[0])

	def __GetCurrentFrame_numpy(self, int fmt = PIX_FMT_RGB24):
		cdef AVFrame *pFrame
		cdef unsigned int numBytes
		cdef numpy.ndarray[numpy.uint8_t, ndim=3] arry
		cdef int width,height
		cdef SwsContext *scale_context
		
		width = self.CodecCtx.width
		height = self.CodecCtx.height
		
		# FIXME: Support any format.
		if fmt != PIX_FMT_RGB24:
			raise ValueError, "Only PIX_FMT_RGB24 is supported right now."
			
		pFrame = avcodec_alloc_frame()
		if pFrame == NULL:
			raise MemoryError("Unable to allocate  AVFrame")
			
		# Determine required buffer size and allocate buffer
		numBytes=avpicture_get_size(fmt, width, height)
		
		arry = numpy.empty((width,height,3), dtype = numpy.uint8)
		
		avpicture_fill(<AVPicture *>pFrame, <void*>arry.data, fmt, width, height)
		
		scale_context = sws_getContext(self.CodecCtx.width, self.CodecCtx.height, self.CodecCtx.pix_fmt, width, height, fmt, SWS_BICUBIC, NULL, NULL, NULL)
		
		if scale_context == NULL:
			av_free(pFrame)
			raise MemoryError, "Unable to allocate SwsContext"
			
		sws_scale(scale_context,<uint8_t**>self.frame.data,self.frame.linesize,0,height,<uint8_t **>pFrame.data,<int *>pFrame.linesize)
		sws_freeContext(scale_context)
		av_free(pFrame)
		return arry
		
	def __GetCurrentFrame_cairo(self):
		cdef AVFrame *pFrame
		cdef object buf_obj
		cdef int numBytes
		cdef int width,height
		
		width = self.CodecCtx.width
		height = self.CodecCtx.height
		
		pFrame = self.ConvertToRGBA(self.frame, self.CodecCtx)
		
		numBytes = avpicture_get_size(PIX_FMT_RGB32, width, height)
		buf_obj = PyBuffer_FromReadWriteMemory(pFrame.data[0],numBytes)
		
		# While we requsted 32 bit data, the alpha data is all transparent when moved to cairo, so we
		# tell cairo it's RGBX so the X is ignored. Cairo always uses 32 bits of data.
		surface = cairo.ImageSurface.create_for_data(buf_obj,cairo.FORMAT_RGB24,width,height,pFrame.linesize[0])
		
		return surface
		
	def __GetCurrentFrame_PIL(self):
		cdef AVFrame *pFrameRGB
		cdef object buf_obj
		cdef int numBytes

		pFrameRGB = self.ConvertToRGB24(self.frame,self.CodecCtx)
		numBytes=avpicture_get_size(PIX_FMT_RGB24, self.CodecCtx.width, self.CodecCtx.height)
		buf_obj = PyBuffer_FromMemory(pFrameRGB.data[0],numBytes)

		img_image = Image.fromstring("RGB",(self.CodecCtx.width,self.CodecCtx.height),buf_obj,"raw","RGB",pFrameRGB.linesize[0],1)
		PyMem_Free(pFrameRGB.data[0])
		av_free(pFrameRGB)
		return img_image
		
		
	def GetCurrentFrame(self):
		if self.image_library == IMAGE_LIBRARY_PIL:
			return self.__GetCurrentFrame_PIL()
		elif self.image_library == IMAGE_LIBRARY_CAIRO:
			return self.__GetCurrentFrame_cairo()
		elif self.image_library == IMAGE_LIBRARY_NUMPY:
			return self.__GetCurrentFrame_numpy()
		else:
			raise ValueError, "Unknown iamge library"
			
	def __next_frame(self):
		cdef int ret
		cdef int frameFinished
		cdef int64_t pts,pts2
		cdef AVStream *stream

		frameFinished = 0
		while frameFinished == 0:
			self.packet.stream_index = -1
			while self.packet.stream_index != self.videoStream:
				ret = av_read_frame(self.FormatCtx,&self.packet)
				if ret < 0:
					raise IOError("Unable to read frame: %d" % ret)
			ret = avcodec_decode_video(self.CodecCtx, self.frame, &frameFinished, self.packet.data, self.packet.size)
			if ret < 0:
				raise IOError("Unable to decode video picture: %d" % ret)

		if self.packet.pts == AV_NOPTS_VALUE:
			pts = self.packet.dts
		else:
			pts = self.packet.pts
		stream = self.FormatCtx.streams[self.videoStream]
		return av_rescale(pts,AV_TIME_BASE * <int64_t>stream.time_base.num,stream.time_base.den)

	def GetNextFrame(self):
		self.__next_frame()
		return self.GetCurrentFrame()		       

	def build_index(self,fast = True):
		if fast == True:
			return self.build_index_fast()
		else:
			return self.build_index_full()
			
	def build_index_full(self):
		cdef int ret,ret2
		
		cdef int frameFinished
		cdef AVStream *stream
		cdef int64_t myPts,pts,time_base
		cdef int frame_no
		
		if self.index is not None:
			# already indexed
			return
		self.index = {}
		self.keyframes = []
		stream = self.FormatCtx.streams[self.videoStream]
		time_base = AV_TIME_BASE * <int64_t>stream.time_base.num
		ret = av_seek_frame(self.FormatCtx,self.videoStream, 0, AVSEEK_FLAG_BACKWARD)
		if ret < 0:
			raise IOError("Error rewinding stream for full indexing: %d" % ret)
		avcodec_flush_buffers(self.CodecCtx)
		myPts = av_rescale(0,time_base,stream.time_base.den)
		frame_no = 0
		while True:
			frameFinished = 0
			while frameFinished == 0:
				ret = av_read_frame(self.FormatCtx, &self.packet)
				if ret < 0:
					# check for eof condition
					ret2 = url_feof(self.FormatCtx.pb)
					if ret2 == 0:
						raise IOError("Error reading frame for full indexing: %d" % ret)
					else:
						frameFinsished = 1
						break
				if self.packet.stream_index != self.videoStream:
					# only looking for video packets
					continue
				if self.packet.pts == AV_NOPTS_VALUE:
					pts = self.packet.dts
				else:
					pts = self.packet.pts
				myPts = av_rescale(pts,time_base,stream.time_base.den)
				
				ret = avcodec_decode_video(self.CodecCtx,self.frame,&frameFinished,self.packet.data,self.packet.size)
				if ret < 0:
					raise IOError("Unable to decode video picture: %d" % ret)
			if self.frame.pict_type == FF_I_TYPE:
				myType = 'I'
			elif self.frame.pict_type == FF_P_TYPE:
				myType = 'P'
			elif self.frame.pict_type == FF_B_TYPE:
				myType = 'B'
			elif self.frame.pict_type == FF_S_TYPE:
				myType = 'S'
			elif self.frame.pict_type == FF_SI_TYPE:
				myType = 'SI'
			elif self.frame.pict_type == FF_SP_TYPE:
				myType = 'SP'
			else:
				myType = 'U'
			self.index[frame_no] = (myPts,myType)
			frame_no = frame_no + 1
			if self.frame.key_frame:
				self.keyframes.append(myPts)
				
		ret = av_seek_frame(self.FormatCtx,self.videoStream, 0, AVSEEK_FLAG_BACKWARD)
		if ret < 0:
			raise IOError("Error rewinding stream after full indexing: %d" % ret)		
		avcodec_flush_buffers(self.CodecCtx)
		
	def build_index_fast(self):
		cdef int ret,ret2
		cdef int64_t myPts,pts,time_base
		cdef AVStream *stream
		
		if self.keyframes is not None:
			# already fast indexed
			return
		self.keyframes = []
		stream = self.FormatCtx.streams[self.videoStream]
		ret = av_seek_frame(self.FormatCtx,self.videoStream, 0, AVSEEK_FLAG_BACKWARD)
		if ret < 0:
			raise IOError("Error rewinding stream for fast indexing: %d" % ret)
		
		
		avcodec_flush_buffers(self.CodecCtx)
		time_base = AV_TIME_BASE * <int64_t>stream.time_base.num
		frame_no = 0

		self.CodecCtx.skip_idct = AVDISCARD_NONKEY
		self.CodecCtx.skip_frame = AVDISCARD_NONKEY
		while True:
			ret = av_read_frame(self.FormatCtx, &self.packet)
			if ret < 0:
				ret2 = url_feof(self.FormatCtx.pb)
				if  ret2 == 0:
					raise IOError("Error reading frame for fast indexing: %d" % ret)
				else:
					break
			if self.packet.stream_index != self.videoStream:
				continue
			if self.packet.pts == AV_NOPTS_VALUE:
				pts = self.packet.dts
			else:
				pts = self.packet.pts
			myPts = av_rescale(pts,time_base,stream.time_base.den)
			self.keyframes.append(myPts)
		self.CodecCtx.skip_idct = AVDISCARD_ALL
		self.CodecCtx.skip_frame = AVDISCARD_DEFAULT

		ret = av_seek_frame(self.FormatCtx,self.videoStream, 0, AVSEEK_FLAG_BACKWARD)
		if ret < 0:
			raise IOError("Error rewinding stream after fast indexing: %d" % ret)		
		avcodec_flush_buffers(self.CodecCtx)
		
	def GetFrameTime(self, int64_t timestamp):
		cdef int64_t targetPts
		targetPts = timestamp * AV_TIME_BASE
		return self.GetFramePts(targetPts)
		
	def GetFramePts(self,int64_t pts):
		cdef int ret
		cdef int64_t myPts
		cdef AVStream *stream
		cdef int64_t targetPts,scaled_start_time
		
		stream = self.FormatCtx.streams[self.videoStream]

		scaled_start_time = av_rescale(stream.start_time,AV_TIME_BASE * <int64_t>stream.time_base.num,stream.time_base.den)
		targetPts = pts + scaled_start_time

		# why doesn't this work? It should be possible to seek only the video stream
		#ret = av_seek_frame(self.FormatCtx,self.videoStream,targetPts, AVSEEK_FLAG_BACKWARD)
		ret = av_seek_frame(self.FormatCtx,-1,targetPts, AVSEEK_FLAG_BACKWARD)
		if ret < 0:
			raise IOError("Unable to seek: %d" % ret)
		avcodec_flush_buffers(self.CodecCtx)
		
		# if we hurry it we can get bad frames later in the GOP
		self.CodecCtx.skip_idct = AVDISCARD_BIDIR
		self.CodecCtx.skip_frame = AVDISCARD_BIDIR
		
		#self.CodecCtx.hurry_up = 1
		hurried_frames = 0
		while True:
			myPts = self.__next_frame()
			if myPts >= targetPts:
				break

		#self.CodecCtx.hurry_up = 0
		
		self.CodecCtx.skip_idct = AVDISCARD_DEFAULT
		self.CodecCtx.skip_frame = AVDISCARD_DEFAULT
		return self.GetCurrentFrame()
			
	def GetFrameNo(self, int frame_no):
		cdef int ret,steps,i
		cdef int64_t myPts
		cdef float my_timestamp
		cdef float frame_rate
		cdef AVStream *stream
		
		stream = self.FormatCtx.streams[self.videoStream]
		#if self.keyframes is None:
			# no index at all, so figure out the pts from the frame rate and frame_no
			# this seems to be accurate enough for my MPEGs, so I'm not sure its worth
			# it to index the stream at all
			# 
		# OK, I'm going to go with this as the only implementation until I find
		# a reason to do it anyother way
			
		frame_rate = (<float>stream.r_frame_rate.num / <float>stream.r_frame_rate.den)
		my_timestamp = frame_no / frame_rate
		return self.GetFrameTime(my_timestamp)
			
		
		if self.index is None:
			# we don't have a full index, so we'll have to fake it from the keyframes
			index = frame_no
			steps = 0
			while index not in self.keyframes:
				index = index - 1
				steps = steps + 1
				
			ret = av_seek_frame(self.FormatCtx, self.videoStream, self.keyframes[index], AVSEEK_FLAG_BACKWARD)
			avcodec_flush_buffers(self.CodecCtx)
			for i from 0 <= i < steps:
				myPts = self.__next_frame()
			return self.GetCurrentFrame() 
		else:
			# use the full index here, I deleted the code but don't seem to need it anyway
			pass
