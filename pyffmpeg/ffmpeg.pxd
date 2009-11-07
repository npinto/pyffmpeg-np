ctypedef unsigned char uint8_t
ctypedef signed long long int64_t

cdef enum:
	SEEK_SET = 0
	SEEK_CUR = 1
	SEEK_END = 2
	
cdef extern from "Python.h":
	ctypedef int size_t
	object PyBuffer_FromMemory(	void *ptr, int size)
	object PyString_FromStringAndSize(char *s, int len)
	void* PyMem_Malloc( size_t n)
	void PyMem_Free( void *p)

cdef extern from "libavutil/mathematics.h":
	int64_t av_rescale(int64_t a, int64_t b, int64_t c)
	
cdef extern from "libavutil/log.h":
	int av_log_get_level()
	void av_log_set_level(int)
	
cdef extern from "libavutil/avutil.h":
	cdef enum PixelFormat:
		PIX_FMT_NONE= -1,
		PIX_FMT_YUV420P,   #< Planar YUV 4:2:0, 12bpp, (1 Cr & Cb sample per 2x2 Y samples)
		PIX_FMT_YUYV422,   #< Packed YUV 4:2:2, 16bpp, Y0 Cb Y1 Cr
		PIX_FMT_RGB24,     #< Packed RGB 8:8:8, 24bpp, RGBRGB...
		PIX_FMT_BGR24,     #< Packed RGB 8:8:8, 24bpp, BGRBGR...
		PIX_FMT_YUV422P,   #< Planar YUV 4:2:2, 16bpp, (1 Cr & Cb sample per 2x1 Y samples)
		PIX_FMT_YUV444P,   #< Planar YUV 4:4:4, 24bpp, (1 Cr & Cb sample per 1x1 Y samples)
		PIX_FMT_RGB32,     #< Packed RGB 8:8:8, 32bpp, (msb)8A 8R 8G 8B(lsb), in cpu endianness
		PIX_FMT_YUV410P,   #< Planar YUV 4:1:0,  9bpp, (1 Cr & Cb sample per 4x4 Y samples)
		PIX_FMT_YUV411P,   #< Planar YUV 4:1:1, 12bpp, (1 Cr & Cb sample per 4x1 Y samples)
		PIX_FMT_RGB565,    #< Packed RGB 5:6:5, 16bpp, (msb)   5R 6G 5B(lsb), in cpu endianness
		PIX_FMT_RGB555,    #< Packed RGB 5:5:5, 16bpp, (msb)1A 5R 5G 5B(lsb), in cpu endianness most significant bit to 0
		PIX_FMT_GRAY8,     #<        Y        ,  8bpp
		PIX_FMT_MONOWHITE, #<        Y        ,  1bpp, 0 is white, 1 is black
		PIX_FMT_MONOBLACK, #<        Y        ,  1bpp, 0 is black, 1 is white
		PIX_FMT_PAL8,      #< 8 bit with PIX_FMT_RGB32 palette
		PIX_FMT_YUVJ420P,  #< Planar YUV 4:2:0, 12bpp, full scale (jpeg)
		PIX_FMT_YUVJ422P,  #< Planar YUV 4:2:2, 16bpp, full scale (jpeg)
		PIX_FMT_YUVJ444P,  #< Planar YUV 4:4:4, 24bpp, full scale (jpeg)
		PIX_FMT_XVMC_MPEG2_MC,#< XVideo Motion Acceleration via common packet passing(xvmc_render.h)
		PIX_FMT_XVMC_MPEG2_IDCT,
		PIX_FMT_UYVY422,   #< Packed YUV 4:2:2, 16bpp, Cb Y0 Cr Y1
		PIX_FMT_UYYVYY411, #< Packed YUV 4:1:1, 12bpp, Cb Y0 Y1 Cr Y2 Y3
		PIX_FMT_BGR32,     #< Packed RGB 8:8:8, 32bpp, (msb)8A 8B 8G 8R(lsb), in cpu endianness
		PIX_FMT_BGR565,    #< Packed RGB 5:6:5, 16bpp, (msb)   5B 6G 5R(lsb), in cpu endianness
		PIX_FMT_BGR555,    #< Packed RGB 5:5:5, 16bpp, (msb)1A 5B 5G 5R(lsb), in cpu endianness most significant bit to 1
		PIX_FMT_BGR8,      #< Packed RGB 3:3:2,  8bpp, (msb)2B 3G 3R(lsb)
		PIX_FMT_BGR4,      #< Packed RGB 1:2:1,  4bpp, (msb)1B 2G 1R(lsb)
		PIX_FMT_BGR4_BYTE, #< Packed RGB 1:2:1,  8bpp, (msb)1B 2G 1R(lsb)
		PIX_FMT_RGB8,      #< Packed RGB 3:3:2,  8bpp, (msb)2R 3G 3B(lsb)
		PIX_FMT_RGB4,      #< Packed RGB 1:2:1,  4bpp, (msb)1R 2G 1B(lsb)
		PIX_FMT_RGB4_BYTE, #< Packed RGB 1:2:1,  8bpp, (msb)1R 2G 1B(lsb)
		PIX_FMT_NV12,      #< Planar YUV 4:2:0, 12bpp, 1 plane for Y and 1 for UV
		PIX_FMT_NV21,      #< as above, but U and V bytes are swapped
		
		PIX_FMT_RGB32_1,   #< Packed RGB 8:8:8, 32bpp, (msb)8R 8G 8B 8A(lsb), in cpu endianness
		PIX_FMT_BGR32_1,   #< Packed RGB 8:8:8, 32bpp, (msb)8B 8G 8R 8A(lsb), in cpu endianness
		
		PIX_FMT_GRAY16BE,  #<        Y        , 16bpp, big-endian
		PIX_FMT_GRAY16LE,  #<        Y        , 16bpp, little-endian
		PIX_FMT_YUV440P,   #< Planar YUV 4:4:0 (1 Cr & Cb sample per 1x2 Y samples)
		PIX_FMT_YUVJ440P,  #< Planar YUV 4:4:0 full scale (jpeg)
		PIX_FMT_YUVA420P,  #< Planar YUV 4:2:0, 20bpp, (1 Cr & Cb sample per 2x2 Y & A samples)
		PIX_FMT_NB,        #< number of pixel formats, DO NOT USE THIS if you want to link with shared libav* because the number of formats might differ between versions

cdef extern from "libavcodec/avcodec.h":
	# use an unamed enum for defines
	cdef enum:
		AVSEEK_FLAG_BACKWARD = 1 #< seek backward
		AVSEEK_FLAG_BYTE     = 2 #< seeking based on position in bytes
		AVSEEK_FLAG_ANY      = 4 #< seek to any frame, even non keyframes
		CODEC_CAP_TRUNCATED = 0x0008
		CODEC_FLAG_TRUNCATED = 0x00010000 # input bitstream might be truncated at a random location instead of only at frame boundaries
		AV_TIME_BASE = 1000000
		FF_I_TYPE = 1 # Intra
		FF_P_TYPE = 2 # Predicted
		FF_B_TYPE = 3 # Bi-dir predicted
		FF_S_TYPE = 4 # S(GMC)-VOP MPEG4
		FF_SI_TYPE = 5
		FF_SP_TYPE = 6

		AV_NOPTS_VALUE = <int64_t>0x8000000000000000

	enum AVDiscard:
		# we leave some space between them for extensions (drop some keyframes for intra only or drop just some bidir frames)
		AVDISCARD_NONE   = -16 # discard nothing
		AVDISCARD_DEFAULT=   0 # discard useless packets like 0 size packets in avi
		AVDISCARD_NONREF =   8 # discard all non reference
		AVDISCARD_BIDIR  =  16 # discard all bidirectional frames
		AVDISCARD_NONKEY =  32 # discard all frames except keyframes
		AVDISCARD_ALL    =  48 # discard all
		
		
	struct AVCodecContext:
		int codec_type
		int codec_id
		int flags
		int width
		int height
		int pix_fmt
		int frame_number
		int hurry_up
		int skip_idct
		int skip_frame
		
	struct AVRational:
		int num
		int den

	enum CodecType:
		CODEC_TYPE_UNKNOWN = -1
		CODEC_TYPE_VIDEO = 0
		CODEC_TYPE_AUDIO = 1
		CODEC_TYPE_DATA = 2
		CODEC_TYPE_SUBTITLE = 3

	struct AVCodec:
		char *name
		int type
		int id
		int priv_data_size
		int capabilities
		AVCodec *next
		AVRational *supported_framerates #array of supported framerates, or NULL if any, array is terminated by {0,0}
		int *pix_fmts       #array of supported pixel formats, or NULL if unknown, array is terminanted by -1

	struct AVPacket:
		int64_t pts                            #< presentation time stamp in time_base units
		int64_t dts                            #< decompression time stamp in time_base units
		char *data
		int   size
		int   stream_index
		int   flags
		int   duration                      #< presentation duration in time_base units (0 if not available)
		void  *priv
		int64_t pos                            #< byte position in stream, -1 if unknown

	struct AVFrame:
		char *data[4]
		int linesize[4]
		int64_t pts
		int pict_type
		int key_frame

	struct AVPicture:
		pass
	AVCodec *avcodec_find_decoder(int id)
	int avcodec_open(AVCodecContext *avctx, AVCodec *codec)
	int avcodec_decode_video(AVCodecContext *avctx, AVFrame *picture,
                         int *got_picture_ptr,
                         char *buf, int buf_size)
	int avpicture_fill(AVPicture *picture, void *ptr,
                   int pix_fmt, int width, int height)
	AVFrame *avcodec_alloc_frame()
	int avpicture_get_size(int pix_fmt, int width, int height)
	int avpicture_layout(AVPicture* src, int pix_fmt, int width, int height,
                     unsigned char *dest, int dest_size)
	
	void av_free(void *ptr)
	void av_freep(void *arg)
				
	void avcodec_flush_buffers(AVCodecContext *avctx)



cdef extern from "libavformat/avformat.h":
	struct AVFrac:
		int64_t val, num, den

	void av_register_all()

	struct AVCodecParserContext:
		pass

	struct AVIndexEntry:
		pass

	struct AVStream:
		int index    #/* stream index in AVFormatContext */
		int id       #/* format specific stream id */
		AVCodecContext *codec #/* codec context */
		# real base frame rate of the stream.
		# for example if the timebase is 1/90000 and all frames have either
		# approximately 3600 or 1800 timer ticks then r_frame_rate will be 50/1
		AVRational r_frame_rate
		void *priv_data
		# internal data used in av_find_stream_info()
		int64_t codec_info_duration
		int codec_info_nb_frames
		# encoding: PTS generation when outputing stream
		AVFrac pts
		# this is the fundamental unit of time (in seconds) in terms
		# of which frame timestamps are represented. for fixed-fps content,
		# timebase should be 1/framerate and timestamp increments should be
		# identically 1.
		AVRational time_base
		int pts_wrap_bits # number of bits in pts (used for wrapping control)
		# ffmpeg.c private use
		int stream_copy   # if TRUE, just copy stream
		int discard       # < selects which packets can be discarded at will and dont need to be demuxed
		# FIXME move stuff to a flags field?
		# quality, as it has been removed from AVCodecContext and put in AVVideoFrame
		# MN:dunno if thats the right place, for it
		float quality
		# decoding: position of the first frame of the component, in
		# AV_TIME_BASE fractional seconds.
		int64_t start_time
		# decoding: duration of the stream, in AV_TIME_BASE fractional
		# seconds.
		int64_t duration
		char language[4] # ISO 639 3-letter language code (empty string if undefined)
		# av_read_frame() support
		int need_parsing                  # < 1->full parsing needed, 2->only parse headers dont repack
		AVCodecParserContext *parser
		int64_t cur_dts
		int last_IP_duration
		int64_t last_IP_pts
		# av_seek_frame() support
		AVIndexEntry *index_entries # only used if the format does not support seeking natively
		int nb_index_entries
		int index_entries_allocated_size
		int64_t nb_frames                 # < number of frames in this stream if known or 0

	struct ByteIOContext:
		pass

	struct AVFormatContext:
		int nb_streams
		AVStream **streams
		int64_t timestamp
		int64_t start_time
		AVStream *cur_st
		AVPacket cur_pkt
		ByteIOContext *pb
		# decoding: total file size. 0 if unknown
		int64_t file_size
		int64_t duration
		# decoding: total stream bitrate in bit/s, 0 if not
		# available. Never set it directly if the file_size and the
		# duration are known as ffmpeg can compute it automatically. */
		int bit_rate
		# av_seek_frame() support
		int64_t data_offset    # offset of the first packet
		int index_built
		

	struct AVInputFormat:
		pass

	struct AVFormatParameters:
		pass

	int av_open_input_file(AVFormatContext **ic_ptr, char *filename,
                       AVInputFormat *fmt,
                       int buf_size,
                       AVFormatParameters *ap)
	int av_find_stream_info(AVFormatContext *ic)

	void dump_format(AVFormatContext *ic,
                 int index,
                 char *url,
                 int is_output)
	void av_free_packet(AVPacket *pkt)
	int av_read_packet(AVFormatContext *s, AVPacket *pkt)
	int av_read_frame(AVFormatContext *s, AVPacket *pkt)
	int av_seek_frame(AVFormatContext *s, int stream_index, int64_t timestamp, int flags)
	int av_seek_frame_binary(AVFormatContext *s, int stream_index, int64_t target_ts, int flags)

	void av_parser_close(AVCodecParserContext *s)

	int av_index_search_timestamp(AVStream *st, int64_t timestamp, int flags)


cdef extern from "libavformat/avio.h":
	int url_ferror(ByteIOContext *s)
	int url_feof(ByteIOContext *s)
	
# use the new swscale interface
cdef extern from "libswscale/swscale.h":
	cdef enum:
		LIBSWSCALE_VERSION_INT
		
	cdef enum:
		# values for the flags, the stuff on the command line is different
		SWS_FAST_BILINEAR     = 1
		SWS_BILINEAR	      = 2
		SWS_BICUBIC	      = 4
		SWS_X		      = 8
		SWS_POINT	   = 0x10
		SWS_AREA	   = 0x20
		SWS_BICUBLIN	   = 0x40
		SWS_GAUSS	   = 0x80
		SWS_SINC	  = 0x100
		SWS_LANCZOS	  = 0x200
		SWS_SPLINE	  = 0x400
		
	struct SwsContext:
		pass
	struct SwsVector:
		double *coeff
		int length
	struct SwsFilter:
		SwsVector *lumH
		SwsVector *lumV
		SwsVector *chrH
		SwsVector *chrV

	void sws_freeContext(SwsContext *swsContext)

	SwsContext *sws_getContext(int srcW, int srcH, int srcFormat, int dstW, int dstH, int dstFormat, int flags,SwsFilter *srcFilter, SwsFilter *dstFilter, double *param)
	
	int sws_scale(SwsContext *context, uint8_t* src[], int srcStride[], int srcSliceY,int srcSliceH, uint8_t* dst[], int dstStride[])

