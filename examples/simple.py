import pyffmpeg
import Image

import os
mypath = os.path.dirname(os.path.realpath(__file__)) + '/'

video_fname = os.path.join(mypath, 'myvideo.flv')

stream = pyffmpeg.VideoStream()
stream.open(video_fname)
# Get the first frame as a PIL image
image = stream.GetFrameNo(0)
print "Retrivied frame number 0 from the video stream as PIL Image"
# Save it to a PNG file
image.save(os.path.join(mypath, 'firstframe.png'))
print "Saved to firstframe.png."

# Change the frame format to numpy.
# Note that the stream wasn't closed or re-opened
stream.SetImageLibrary(pyffmpeg.image_library_numpy)

# Get a different frame, GetCurrentFrame could also be used to return 
nimage = stream.GetFrameNo(256)

# Print some information about the returned array
print
print "Got numpy format frame of type %s" % type(nimage)
print "It's shape is",nimage.shape, "This is Width x Height x bytes per pixel"
print "It takes %d bytes of memory" % nimage.nbytes

# Convert the numpy array into a PIL image.
image = Image.frombuffer("RGB",nimage.shape[0:2],nimage.data,"raw","RGB",nimage.shape[0] * nimage.shape[2],1)
# Save it to a PNG file as well
image.save(os.path.join(mypath, 'numpy_frame.png'))
print "Wrote numpy frame to numpy_frame.png by converting to PIL image"

# And now a cairo image surface
stream.SetImageLibrary(pyffmpeg.image_library_cairo)
# Returns a cairo surface
surf = stream.GetFrameNo(128)
print
print "Got cairo surface with type %s" % type(surf)
surf.write_to_png(os.path.join(mypath, "cairo_frame.png"))
print "Wrote to file cairo_frame.png using write_to_png()"

print
print "Done!"
