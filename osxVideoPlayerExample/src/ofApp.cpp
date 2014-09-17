#include "ofApp.h"

static int const kProgressBarHeight = 30;

//--------------------------------------------------------------
void ofApp::setup(){
	video.loadMovie("hands.m4v");
    video.setLoopState(OF_LOOP_NORMAL);
	video.play();
}

//--------------------------------------------------------------
void ofApp::update(){
    if(!video.isLoaded()) {
        return;
    }
    
    video.update();
}

//--------------------------------------------------------------
void ofApp::draw(){
	ofSetColor(255);
    
    ofColor yelloColor(255, 255, 0, 255 * 0.7); // yellow.
    ofColor blackColor(0); // black.

    //---------------------------------------------------------- draw video texture to fullscreen.
    ofRectangle screenRect(0, 0, ofGetWidth(), ofGetHeight());
    ofRectangle videoRect(0, 0, video.getWidth(), video.getHeight());
    ofRectangle videoFullscreenRect = videoRect;
    videoFullscreenRect.scaleTo(screenRect, OF_ASPECT_RATIO_KEEP_BY_EXPANDING);
    
    video.getTexture()->draw(videoFullscreenRect);
    
    //---------------------------------------------------------- draw progress bar.
    float progress = video.getPosition();
    ofRectangle progressRect;
    progressRect.width = ofGetWidth();
    progressRect.height = kProgressBarHeight;
    progressRect.y = ofGetHeight() - progressRect.height;
    
    ofSetColor(blackColor);
    ofRect(progressRect);
    
    progressRect.width = ofMap(progress, 0.0, 1.0, 0.0, ofGetWidth());
    
    ofSetColor(yelloColor);
    ofRect(progressRect);
    ofSetColor(255);
    
    //---------------------------------------------------------- draw info.
    int x = 20;
    int y = 0;
    string str = "";
    
    str = "LOADED = ";
    if(video.isLoaded() == true) {
        str += "TRUE";
    } else {
        str += "FALSE";
    }
    ofDrawBitmapStringHighlight(str, x, y+=22, yelloColor, blackColor);
    
    str = "PLAYING = ";
    if(video.isPlaying() == true) {
        str += "TRUE";
    } else {
        str += "FALSE";
    }
    ofDrawBitmapStringHighlight(str, x, y+=22, yelloColor, blackColor);
    
    str = "NEW FRAME = ";
    if(video.isFrameNew() == true) {
        str += "TRUE";
    } else {
        str += "FALSE";
    }
    ofDrawBitmapStringHighlight(str, x, y+=22, yelloColor, blackColor);
    
    str = "POSITION = ";
    str += ofToString(video.getPosition(), 3);
    ofDrawBitmapStringHighlight(str, x, y+=22, yelloColor, blackColor);
    
    str = "FRAME NUM = ";
    str += ofToString(video.getCurrentFrame());
    ofDrawBitmapStringHighlight(str, x, y+=22, yelloColor, blackColor);
}

//--------------------------------------------------------------
void ofApp::handleProgressBarClick(int x, int y) {
    ofRectangle progressRect(0, ofGetHeight()-kProgressBarHeight, ofGetWidth(), kProgressBarHeight);
    if(progressRect.inside(x, y) == true) {
        float progress = ofMap(x, 0, ofGetWidth(), 0.0, 1.0, true);
        video.setPosition(progress);
    }
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if(key == ' ') {
        bool bPaused = video.isPaused();
        video.setPaused(!bPaused);
    }
}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){
    handleProgressBarClick(x, y);
}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){
    handleProgressBarClick(x, y);
}

//--------------------------------------------------------------
void ofApp::mouseReleased(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::windowResized(int w, int h){

}

//--------------------------------------------------------------
void ofApp::gotMessage(ofMessage msg){

}

//--------------------------------------------------------------
void ofApp::dragEvent(ofDragInfo dragInfo){ 

}