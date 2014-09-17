//
//  ofxAVFoundationVideoPlayer.h
//  Created by lukasz karluk on 06/07/14.
//  http://julapy.com
//

#pragma once

#include "ofBaseTypes.h"
#include "ofPixels.h"
#include "ofTexture.h"

class ofxAVFoundationVideoPlayer : public ofBaseVideoPlayer {
	
public:
	
	ofxAVFoundationVideoPlayer();
	~ofxAVFoundationVideoPlayer();
	   
    void enableTextureCache();
    void disableTextureCache();
    
    bool loadMovie(string name);
    void close();
    void update();
	
	bool setPixelFormat(ofPixelFormat pixelFormat);
	ofPixelFormat getPixelFormat() const;
	
    void play();
    void stop();
	
    bool isFrameNew() const;
    unsigned char * getPixels();
    ofPixels & getPixelsRef();
    const ofPixels & getPixelsRef() const;
    ofTexture *	getTexture();
    void initTextureCache();
    void killTextureCache();
	
    float getWidth() const;
    float getHeight() const;
	
    bool isPaused() const;
    bool isLoaded() const;
    bool isPlaying() const;
	
    float getPosition() const;
    float getSpeed() const;
    float getDuration() const;
    bool getIsMovieDone() const;
	
    void setPaused(bool bPause);
    void setPosition(float pct);
    void setVolume(float volume); // 0..1
    void setLoopState(ofLoopType state);
    void setSpeed(float speed);
    void setFrame(int frame);  // frame 0 = first frame...
	
    int	getCurrentFrame() const;
    int	getTotalNumFrames() const;
    ofLoopType getLoopState() const;
	
    void firstFrame();
    void nextFrame();
    void previousFrame();
    
	void * getAVFoundationVideoPlayer();
    
protected:
    
    void updatePixelsToRGB();
	
	void * videoPlayer;
    
    bool bFrameNew;
    bool bResetPixels;
    bool bResetTexture;
    bool bUpdatePixels;
    bool bUpdatePixelsToRgb;
    bool bUpdateTexture;
    bool bTextureCacheSupported;
    bool bTextureCacheEnabled;
	
    ofPixels pixels;
	GLubyte * pixelsRGB;
    GLubyte * pixelsRGBA;
    GLint internalGLFormat;
	ofPixelFormat internalPixelFormat;
	ofTexture videoTexture;
};

