import pyffmpeg

stream = pyffmpeg.VideoStream()
stream.open('myvideo.flv')
image = stream.GetFrameNo(0)
image.save('firstframe.png')

