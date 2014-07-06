#include "ofApp.h"

#import "VideoPlayerControls.h"
#import "VideoPlayerControlsDelegateForOF.h"
#import "OFAVFoundationVideoPlayer.h"

//-------------------------------------------------------------- video controls.
static VideoPlayerControls * controls = nil;
static bool bPlayingBeforeScrub = false;
static bool bScrubbing = false;

//--------------------------------------------------------------
void ofApp::setup() {
	ofSetFrameRate(30);
	ofBackground(225, 225, 225);
    
	video.loadMovie("hands.m4v");
	video.play();
    
    controls = [[VideoPlayerControls alloc] init];
    controls.delegate = [[VideoPlayerControlsDelegateForOF alloc] initWithApp:this];
    [ofxiOSGetGLParentView() addSubview:controls.view];
    
    OFAVFoundationVideoPlayer * avVideoPlayer;
    avVideoPlayer = (OFAVFoundationVideoPlayer *)video.getAVFoundationVideoPlayer();
    [avVideoPlayer setVideoPosition:CGPointMake(0, 240)];
    [ofxiOSGetGLParentView() insertSubview:avVideoPlayer.playerView belowSubview:controls.view];
    avVideoPlayer.playerView.hidden = YES;
}

//--------------------------------------------------------------
void ofApp::update(){
    if(!video.isLoaded()) {
        return;
    }
    
    video.update();

    [controls setNewFrame:video.isFrameNew()];
    
    float position = video.getPosition();
    int timeInSeconds = video.getDuration() * position;
    
    if(!bScrubbing) {   // only update slider position when not already scrubbing.
        [controls setPosition:position];
    }
    [controls setTimeInSeconds:timeInSeconds];
    
    if(video.getIsMovieDone()) {
        [controls setPlay:video.isPlaying()];
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
	
	ofSetColor(255);
    video.getTexture()->draw(0, 0);
    
	if(video.isLoaded()){
        
        // let's move through the "RGB" char array
        // using the red pixel to control the size of a circle.
        
        unsigned char * pixels = video.getPixels();
        int videoW = video.getWidth();
        int videoH = video.getHeight();
        
		ofSetColor(54);
		for (int i = 4; i < videoW; i+=8){
			for (int j = 4; j < videoH; j+=8){
				unsigned char r = pixels[(j * 320 + i)*3];
				float val = 1 - ((float)r / 255.0f);
				ofCircle(i, 240 + j, 4 * val);
			}
		}
    }
    
    ofSetColor(0);
    if(video.getIsMovieDone()){
        ofSetHexColor(0xFF0000);
        ofDrawBitmapString("end of movie", 110, 360);
    }
}

//--------------------------------------------------------------
void ofApp::playPressed() {
    video.setPaused(false);
    [controls setPlay:video.isPlaying()];
}

void ofApp::pausePressed() {
    video.setPaused(true);
    [controls setPlay:video.isPlaying()];
}

void ofApp::scrubBegin() {
    bScrubbing = true;
    
    bPlayingBeforeScrub = video.isPlaying();    // save the last play state.
    video.setPaused(true);
    
    [controls setPlay:video.isPlaying()];
}

void ofApp::scrubToPosition(float position) {
    video.setPosition(position);
}

void ofApp::scrubEnd() {
    if(bPlayingBeforeScrub) {
        video.setPaused(false);
    }
    
    [controls setPlay:video.isPlaying()];
    
    bScrubbing = false;
}

void ofApp::loadPressed() {
    video.loadMovie("hands.m4v");
    video.play();
    
    OFAVFoundationVideoPlayer * avVideoPlayer;
    avVideoPlayer = (OFAVFoundationVideoPlayer *)video.getAVFoundationVideoPlayer();
    [avVideoPlayer setVideoPosition:CGPointMake(0, 240)];
    [ofxiOSGetGLParentView() insertSubview:avVideoPlayer.playerView belowSubview:controls.view];
    avVideoPlayer.playerView.hidden = YES;
    
    [controls setLoad:YES];
}

void ofApp::unloadPressed() {
    video.close();
    [controls setLoad:NO];
}

void ofApp::loopOnPressed() {
    video.setLoopState(OF_LOOP_NORMAL);
    [controls setLoop:YES];
}

void ofApp::loopOffPressed() {
    video.setLoopState(OF_LOOP_NONE);
    [controls setLoop:NO];
}

void ofApp::nativeOnPressed() {
    [(OFAVFoundationVideoPlayer *)video.getAVFoundationVideoPlayer() playerView].hidden = NO;
    [controls setNative:YES];
}

void ofApp::nativeOffPressed() {
    [(OFAVFoundationVideoPlayer *)video.getAVFoundationVideoPlayer() playerView].hidden = YES;
    [controls setNative:NO];
}

void ofApp::muteOnPressed() {
    video.setVolume(0.0f);
    [controls setMute:YES];
}

void ofApp::muteOffPressed() {
    video.setVolume(1.0f);
    [controls setMute:NO];
}

//--------------------------------------------------------------
void ofApp::exit(){
    if(controls) {
        [controls.view removeFromSuperview];
        controls.delegate = nil;
        [controls release];
        controls = nil;
    }
}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::lostFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotFocus(){
    
}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){
    
}

