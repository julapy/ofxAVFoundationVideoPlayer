#include "ofApp.h"

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
    
    ofRectangle screenRect(0, 0, ofGetWidth(), ofGetHeight());
    ofRectangle videoRect(0, 0, video.getWidth(), video.getHeight());
    ofRectangle videoFullscreenRect = videoRect;
    videoFullscreenRect.scaleTo(screenRect, OF_ASPECT_RATIO_KEEP);
    
    video.getTexture()->draw(videoFullscreenRect);
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){

}

//--------------------------------------------------------------
void ofApp::keyReleased(int key){

}

//--------------------------------------------------------------
void ofApp::mouseMoved(int x, int y){

}

//--------------------------------------------------------------
void ofApp::mouseDragged(int x, int y, int button){

}

//--------------------------------------------------------------
void ofApp::mousePressed(int x, int y, int button){

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