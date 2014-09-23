//
//  ofxAVFoundationVideoPlayer.mm
//  Created by lukasz karluk on 06/07/14.
//  http://julapy.com
//

//--------------------------------------------------------------
#import "ofxAVFoundationVideoPlayer.h"
#import "OFAVFoundationVideoPlayer.h"

//--------------------------------------------------------------
#ifdef TARGET_OF_IOS
CVOpenGLESTextureCacheRef _videoTextureCache = NULL;
CVOpenGLESTextureRef _videoTextureRef = NULL;
#endif

#ifdef TARGET_OSX
CVOpenGLTextureCacheRef _videoTextureCache = NULL;
CVOpenGLTextureRef _videoTextureRef = NULL;
#endif

ofxAVFoundationVideoPlayer::ofxAVFoundationVideoPlayer() {
	videoPlayer = NULL;
	pixelsRGB = NULL;
	pixelsRGBA = NULL;
    internalGLFormat = GL_RGB;
	internalPixelFormat = OF_PIXELS_RGB;
	
    bFrameNew = false;
    bResetPixels = false;
    bResetTexture = false;
    bUpdatePixels = false;
    bUpdatePixelsToRgb = false;
    bUpdateTexture = false;
    bTextureCacheSupported = false;
#ifdef TARGET_OF_IOS
    bTextureCacheSupported = (CVOpenGLESTextureCacheCreate != NULL);
#endif
#ifdef TARGET_OSX
    bTextureCacheSupported = (CVOpenGLTextureCacheCreate != NULL);
#endif
    bTextureCacheEnabled = true;
}

//--------------------------------------------------------------
ofxAVFoundationVideoPlayer::~ofxAVFoundationVideoPlayer() {
	close();
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::enableTextureCache() {
    bTextureCacheEnabled = true;
}

void ofxAVFoundationVideoPlayer::disableTextureCache() {
    bTextureCacheEnabled = false;
    bResetTexture = true;
    killTextureCache();
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::loadMovie(string name) {
	
    if(!videoPlayer) {
        videoPlayer = [[OFAVFoundationVideoPlayer alloc] init];
        [(OFAVFoundationVideoPlayer *)videoPlayer setWillBeUpdatedExternally:YES];
    }
    
    NSString * videoPath = [NSString stringWithUTF8String:ofToDataPath(name).c_str()];
    [(OFAVFoundationVideoPlayer*)videoPlayer loadWithPath:videoPath];
    
    bResetPixels = true;
    bResetTexture = true;
    bUpdatePixels = true;
    bUpdatePixelsToRgb = true;
    bUpdateTexture = true;
    
    bool bCreateTextureCache = true;
    bCreateTextureCache = bCreateTextureCache && (bTextureCacheSupported == true);
    bCreateTextureCache = bCreateTextureCache && (bTextureCacheEnabled == true);
    bCreateTextureCache = bCreateTextureCache && (_videoTextureCache == NULL);
    
    if(bCreateTextureCache == true) {

        CVReturn err;
        
#if defined(TARGET_OF_IOS) && defined(__IPHONE_6_0)
        err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                           NULL,
                                           [EAGLContext currentContext],
                                           NULL,
                                           &_videoTextureCache);
#endif
        
#if defined(TARGET_OF_IOS) && !defined(__IPHONE_6_0)
        err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault,
                                           NULL,
                                           (__bridge void *)[EAGLContext currentContext],
                                           NULL,
                                           &_videoTextureCache);
#endif
        
#ifdef TARGET_OSX
        err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                         NULL,
                                         CGLGetCurrentContext(),
                                         CGLGetPixelFormat(CGLGetCurrentContext()),
                                         NULL,
                                         &_videoTextureCache);
#endif
        
        if(err) {
            NSLog(@"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    
    return true;
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::close() {
	if(videoPlayer != NULL) {
		
		if(pixelsRGBA != NULL) {
			free(pixelsRGBA);
			pixelsRGBA = NULL;
		}
        
		if(pixelsRGB != NULL) {
			free(pixelsRGB);
			pixelsRGB = NULL;
		}
        
        videoTexture.clear();
		
        ((OFAVFoundationVideoPlayer *)videoPlayer).delegate = nil;
		[(OFAVFoundationVideoPlayer *)videoPlayer release];
        
        if(bTextureCacheSupported == true) {
            killTextureCache();
        }
	}
	videoPlayer = NULL;
    
    bFrameNew = false;
    bResetPixels = false;
    bResetTexture = false;
    bUpdatePixels = false;
    bUpdatePixelsToRgb = false;
    bUpdateTexture = false;
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::setPixelFormat(ofPixelFormat _internalPixelFormat) {
	if(_internalPixelFormat == OF_PIXELS_RGB) {
		internalPixelFormat = _internalPixelFormat;
		internalGLFormat = GL_RGB;
		return true;		
    } else if(_internalPixelFormat == OF_PIXELS_RGBA) {
		internalPixelFormat = _internalPixelFormat;
		internalGLFormat = GL_RGBA;
		return true;
    } else if(_internalPixelFormat == OF_PIXELS_BGRA) {
		internalPixelFormat = _internalPixelFormat;	
		internalGLFormat = GL_BGRA;
		return true;
    }
	return false;
}


//--------------------------------------------------------------
ofPixelFormat ofxAVFoundationVideoPlayer::getPixelFormat() const{
	return internalPixelFormat;
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::update() {
    
    bFrameNew = false; // default.
    
    if(!isLoaded()) {
        return;
    }
    
    [(OFAVFoundationVideoPlayer *)videoPlayer update];
    bFrameNew = [(OFAVFoundationVideoPlayer *)videoPlayer isNewFrame]; // check for new frame staright after the call to update.
    
    if(bFrameNew) {
        /**
         *  mark pixels to be updated.
         *  pixels are then only updated if the getPixels() method is called,
         *  internally or externally to this class.
         *  this ensures the pixels are updated only once per frame.
         */
        bUpdatePixels = true;
        bUpdatePixelsToRgb = true;
        bUpdateTexture = true;
    }
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::play() {
    if(videoPlayer == NULL) {
        ofLogWarning("ofxAVFoundationVideoPlayer") << "play(): video not loaded";
    }
    
	[(OFAVFoundationVideoPlayer *)videoPlayer play];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::stop() {
    if(videoPlayer == NULL) {
        return;
    }
    
    [(OFAVFoundationVideoPlayer *)videoPlayer pause];
    [(OFAVFoundationVideoPlayer *)videoPlayer setPosition:0];
}		

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::isFrameNew() const {
	if(videoPlayer != NULL) {
		return bFrameNew;
	}	
	return false;
}

//--------------------------------------------------------------
unsigned char * ofxAVFoundationVideoPlayer::getPixels() {
    
	if(isLoaded() == false) {
        return NULL;
	}
	
    if(bUpdatePixels == false) {
        
        // if pixels have not changed,
        // return the already calculated pixels.
        
        if(internalGLFormat == GL_RGB) {
            
            updatePixelsToRGB();
            return pixelsRGB;
            
        } else if(internalGLFormat == GL_RGBA || internalGLFormat == GL_BGRA) {
            
            return pixelsRGBA;
        }
    }
    
    CGImageRef currentFrameRef;
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    CVImageBufferRef imageBuffer = [(OFAVFoundationVideoPlayer *)videoPlayer getCurrentFrame];
    
    /*Lock the image buffer*/
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    /*Get information about the image*/
    uint8_t *baseAddress	= (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow		= CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width			= CVPixelBufferGetWidth(imageBuffer);
    size_t height			= CVPixelBufferGetHeight(imageBuffer);
    
    /*Create a CGImageRef from the CVImageBufferRef*/
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef newContext = CGBitmapContextCreate(baseAddress,
                                                    width,
                                                    height,
                                                    8,
                                                    bytesPerRow,
                                                    colorSpace,
                                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef newImage	= CGBitmapContextCreateImage(newContext);
    
    currentFrameRef = CGImageCreateCopy(newImage);
    
    /*We release some components*/
    CGContextRelease(newContext);
    CGColorSpaceRelease(colorSpace);
    
    /*We relase the CGImageRef*/
    CGImageRelease(newImage);
    
    /*We unlock the  image buffer*/
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    if(bResetPixels) {
        
        if(pixelsRGBA != NULL) {
            free(pixelsRGBA);
            pixelsRGBA = NULL;
        }
        
        if(pixelsRGB != NULL) {
            free(pixelsRGB);
            pixelsRGB = NULL;
        }
        
        pixelsRGBA = (GLubyte *) malloc(width * height * 4);
        pixelsRGB  = (GLubyte *) malloc(width * height * 3);
        
        bResetPixels = false;
    }
    
    [pool drain];
    
    CGContextRef spriteContext;
    spriteContext = CGBitmapContextCreate(pixelsRGBA,
                                          width,
                                          height,
                                          CGImageGetBitsPerComponent(currentFrameRef),
                                          width * 4,
                                          CGImageGetColorSpace(currentFrameRef),
                                          kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext,
                       CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height),
                       currentFrameRef);
    
    CGContextRelease(spriteContext);
    
    if(internalGLFormat == GL_RGB) {
        updatePixelsToRGB();
    } else if(internalGLFormat == GL_RGBA || internalGLFormat == GL_BGRA) {
        // pixels are already 4 channel.
        // return pixelsRaw instead of pixels (further down).
    }
    
    CGImageRelease(currentFrameRef);
    
    bUpdatePixels = false;
    
    if(internalGLFormat == GL_RGB) {
        return pixelsRGB;
    }  else if(internalGLFormat == GL_RGBA || internalGLFormat == GL_BGRA) {
        return pixelsRGBA;
    }
    
    return NULL;
}

void ofxAVFoundationVideoPlayer::updatePixelsToRGB () {
    if(!bUpdatePixelsToRgb) {
        return;
    }
    
    int width = [(OFAVFoundationVideoPlayer *)videoPlayer getWidth];
    int height = [(OFAVFoundationVideoPlayer *)videoPlayer getHeight];

    unsigned int *isrc4 = (unsigned int *)pixelsRGBA;
    unsigned int *idst3 = (unsigned int *)pixelsRGB;
    unsigned int *ilast4 = &isrc4[width*height-1];
    while (isrc4 < ilast4){
        *(idst3++) = *(isrc4++);
        idst3 = (unsigned int *) (((unsigned char *) idst3) - 1);
    }
    
    bUpdatePixelsToRgb = false;
}

//--------------------------------------------------------------
ofPixelsRef & ofxAVFoundationVideoPlayer::getPixelsRef() {
    return pixels;
}

const ofPixels & ofxAVFoundationVideoPlayer::getPixelsRef() const {
    return pixels;
}

//--------------------------------------------------------------
ofTexture * ofxAVFoundationVideoPlayer::getTexture() {
    
    if(isLoaded() == false) {
        return &videoTexture;
    }
    
    if(bUpdateTexture == false) {
        return &videoTexture;
    }

    if(bTextureCacheSupported == true && bTextureCacheEnabled == true) {
        
        initTextureCache();
        
    } else {

        /**
         *  no video texture cache.
         *  load texture from pixels.
         *  this method is the slower alternative.
         */
        
        int maxTextureSize = 0;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &maxTextureSize);
        
        if([(OFAVFoundationVideoPlayer *)videoPlayer getWidth] > maxTextureSize ||
           [(OFAVFoundationVideoPlayer *)videoPlayer getHeight] > maxTextureSize) {
            ofLogWarning("ofxAVFoundationVideoPlayer") << "getTexture(): "
				<< [(OFAVFoundationVideoPlayer *)videoPlayer getWidth] << "x" << [(OFAVFoundationVideoPlayer *)videoPlayer getHeight]
				<< " video image is bigger then max supported texture size " << maxTextureSize;
            return NULL;
        }
        
        if(bResetTexture) {
            
            videoTexture.allocate([(OFAVFoundationVideoPlayer *)videoPlayer getWidth],
                                  [(OFAVFoundationVideoPlayer *)videoPlayer getHeight],
                                  GL_RGBA);
        }
        
        GLint internalGLFormatCopy = internalGLFormat;
        internalGLFormat = GL_RGBA;
        videoTexture.loadData(getPixels(), 
                              [(OFAVFoundationVideoPlayer *)videoPlayer getWidth],
                              [(OFAVFoundationVideoPlayer *)videoPlayer getHeight],
                              internalGLFormat);
        internalGLFormat = internalGLFormatCopy;
    }
    
    bUpdateTexture = false;
    
    return &videoTexture;
}

//-------------------------------------------------------------- texture cache
void ofxAVFoundationVideoPlayer::initTextureCache() {

    CVImageBufferRef imageBuffer = [(OFAVFoundationVideoPlayer *)videoPlayer getCurrentFrame];
    if(imageBuffer == nil) {
        return;
    }
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    /**
     *  video texture cache is available.
     *  this means we don't have to copy any pixels,
     *  and we can reuse the already existing video texture.
     *  this is very fast! :)
     */
    
    /**
     *  CVOpenGLESTextureCache does this operation for us.
     *  it automatically returns a texture reference which means we don't have to create the texture ourselves.
     *  this creates a slight problem because when we create an ofTexture objects, it also creates a opengl texture for us,
     *  which is unecessary in this case because the texture already exists.
     *  so... we can use ofTexture::setUseExternalTextureID() to get around this.
     */
    
    int videoTextureW = [(OFAVFoundationVideoPlayer *)videoPlayer getWidth];
    int videoTextureH = [(OFAVFoundationVideoPlayer *)videoPlayer getHeight];
    videoTexture.allocate(videoTextureW, videoTextureH, GL_RGBA);
    
    ofTextureData & texData = videoTexture.getTextureData();
    texData.tex_t = 1.0f; // these values need to be reset to 1.0 to work properly.
    texData.tex_u = 1.0f; // assuming this is something to do with the way ios creates the texture cache.

    CVReturn err;
    unsigned int textureCacheID;
    
#ifdef TARGET_OF_IOS
    
    /**
     *  create video texture from video image.
     *  inside this function, ios is creating the texture for us.
     *  a video texture reference is returned.
     */
    err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault,     // CFAllocatorRef allocator
                                                       _videoTextureCache,      // CVOpenGLESTextureCacheRef textureCache
                                                       imageBuffer,             // CVImageBufferRef sourceImage
                                                       NULL,                    // CFDictionaryRef textureAttributes
                                                       texData.textureTarget,   // GLenum target
                                                       texData.glTypeInternal,  // GLint internalFormat
                                                       texData.width,           // GLsizei width
                                                       texData.height,          // GLsizei height
                                                       GL_BGRA,                 // GLenum format
                                                       GL_UNSIGNED_BYTE,        // GLenum type
                                                       0,                       // size_t planeIndex
                                                       &_videoTextureRef);      // CVOpenGLESTextureRef *textureOut
    
    textureCacheID = CVOpenGLESTextureGetName(_videoTextureRef);
    
#endif
    
#ifdef TARGET_OSX
    
    err = CVOpenGLTextureCacheCreateTextureFromImage(NULL,
                                                     _videoTextureCache,
                                                     imageBuffer,
                                                     NULL,
                                                     &_videoTextureRef);

    textureCacheID = CVOpenGLTextureGetName(_videoTextureRef);
    
#endif
    
    videoTexture.setUseExternalTextureID(textureCacheID);
    videoTexture.setTextureMinMagFilter(GL_LINEAR, GL_LINEAR);
    videoTexture.setTextureWrap(GL_CLAMP_TO_EDGE, GL_CLAMP_TO_EDGE);
    if(ofIsGLProgrammableRenderer() == false) {
        videoTexture.bind();
        glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
        videoTexture.unbind();
    }
    
    if(err) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
#ifdef TARGET_OF_IOS
    
    CVOpenGLESTextureCacheFlush(_videoTextureCache, 0);
    if(_videoTextureRef) {
        CFRelease(_videoTextureRef);
        _videoTextureRef = NULL;
    }
    
#endif
    
#ifdef TARGET_OSX

    CVOpenGLTextureCacheFlush(_videoTextureCache, 0);
    if(_videoTextureRef) {
        CVOpenGLTextureRelease(_videoTextureRef);
        _videoTextureRef = NULL;
    }
    
#endif
}

void ofxAVFoundationVideoPlayer::killTextureCache() {
#ifdef TARGET_OF_IOS
    
    if(_videoTextureRef) {
        CFRelease(_videoTextureRef);
        _videoTextureRef = NULL;
    }

    if(_videoTextureCache) {
        CFRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
#endif
    
#ifdef TARGET_OSX
    
    if (_videoTextureRef != NULL) {
        CVOpenGLTextureRelease(_videoTextureRef);
        _videoTextureRef = NULL;
    }
    
    if(_videoTextureCache != NULL) {
        CVOpenGLTextureCacheRelease(_videoTextureCache);
        _videoTextureCache = NULL;
    }
    
#endif
}

//--------------------------------------------------------------
float ofxAVFoundationVideoPlayer::getWidth() const {
    if(videoPlayer == NULL) {
        return 0;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getWidth];
}

//--------------------------------------------------------------
float ofxAVFoundationVideoPlayer::getHeight() const {
    if(videoPlayer == NULL) {
        return 0;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getHeight];
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::isPaused() const {
    if(videoPlayer == NULL) {
        return false;
    }
    
    return ![((OFAVFoundationVideoPlayer *)videoPlayer) isPlaying];
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::isLoaded() const {
    if(videoPlayer == NULL) {
        return false;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) isReady];
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::isPlaying() const {
    if(videoPlayer == NULL) {
        return false;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) isPlaying];
}

//--------------------------------------------------------------
float ofxAVFoundationVideoPlayer::getPosition() const {
    if(videoPlayer == NULL) {
        return 0;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getPosition];
}

//--------------------------------------------------------------
float ofxAVFoundationVideoPlayer::getSpeed() const {
    if(videoPlayer == NULL) {
        return 0;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getSpeed];
}

//--------------------------------------------------------------
float ofxAVFoundationVideoPlayer::getDuration() const {
    if(videoPlayer == NULL) {
        return 0;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getDurationInSec];
}

//--------------------------------------------------------------
bool ofxAVFoundationVideoPlayer::getIsMovieDone() const {
    if(videoPlayer == NULL) {
        return false;
    }
    
    return [((OFAVFoundationVideoPlayer *)videoPlayer) isFinished];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setPaused(bool bPause) {
    if(videoPlayer == NULL) {
        return;
    }
    
    if(bPause) {
        [((OFAVFoundationVideoPlayer *)videoPlayer) pause];
    } else {
        [((OFAVFoundationVideoPlayer *)videoPlayer) play];
    }
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setPosition(float pct) {
    if(videoPlayer == NULL) {
        return;
    }
    
    [((OFAVFoundationVideoPlayer *)videoPlayer) setPosition:pct];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setVolume(float volume) {
    if(videoPlayer == NULL) {
        return;
    }
	if ( volume > 1.0f ){
		ofLogWarning("ofxAVFoundationVideoPlayer") << "setVolume(): expected range is 0-1, limiting requested volume " << volume << " to 1.0";
		volume = 1.0f;
	}
    [((OFAVFoundationVideoPlayer *)videoPlayer) setVolume:volume];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setLoopState(ofLoopType state) {
    if(videoPlayer == NULL) {
        return;
    }
    
    bool bLoop = false;
    if((state == OF_LOOP_NORMAL) || 
       (state == OF_LOOP_PALINDROME)) {
        bLoop = true;
    }
    [((OFAVFoundationVideoPlayer *)videoPlayer) setLoop:bLoop];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setSpeed(float speed) {
    if(videoPlayer == NULL) {
        return;
    }
    
    [((OFAVFoundationVideoPlayer *)videoPlayer) setSpeed:speed];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::setFrame(int frame) {
    if(videoPlayer == NULL) {
        return;
    }

    [((OFAVFoundationVideoPlayer *)videoPlayer) setFrame:frame];
}

//--------------------------------------------------------------
int	ofxAVFoundationVideoPlayer::getCurrentFrame() const {
    if(videoPlayer == NULL){
        return 0;
    }
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getCurrentFrameNum];
}

//--------------------------------------------------------------
int	ofxAVFoundationVideoPlayer::getTotalNumFrames() const {
    if(videoPlayer == NULL){
        return 0;
    }
    return [((OFAVFoundationVideoPlayer *)videoPlayer) getDurationInFrames];
}

//--------------------------------------------------------------
ofLoopType	ofxAVFoundationVideoPlayer::getLoopState() const {
    if(videoPlayer == NULL) {
        return OF_LOOP_NONE;
    }
    
    bool bLoop =  [((OFAVFoundationVideoPlayer *)videoPlayer) getLoop];
    if(bLoop) {
        return OF_LOOP_NORMAL;
    }
    return OF_LOOP_NONE;
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::firstFrame() {
    if(videoPlayer == NULL) {
        return;
    }
    
    [((OFAVFoundationVideoPlayer *)videoPlayer) setPosition:0];
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::nextFrame() {
    int nextFrameNum = ofClamp(getCurrentFrame() + 1, 0, getTotalNumFrames());
    setFrame(nextFrameNum);
}

//--------------------------------------------------------------
void ofxAVFoundationVideoPlayer::previousFrame() {
    int prevFrameNum = ofClamp(getCurrentFrame() - 1, 0, getTotalNumFrames());
    setFrame(prevFrameNum);
}

//--------------------------------------------------------------
void * ofxAVFoundationVideoPlayer::getAVFoundationVideoPlayer() {
    return videoPlayer;
}
