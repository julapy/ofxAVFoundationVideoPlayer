ofxAVFoundationVideoPlayer
==========================

ofxAVFoundationVideoPlayer is video player addon for openFrameworks which runs on iOS and OSX.

The original code is a copy of ofxiOSVideoPlayer and has been part of ofxiOS for a good amount of time.
Adapting to OSX was releatively simple as Apple have been making the AVFoundation framework work identically across iOS and OSX.
More info on the common code base between the two OS's here, https://developer.apple.com/av-foundation/

XCode projects will need to include the following frameworks,
- AVFoundation.framework
- CoreMedia.framework