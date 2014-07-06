#include "ofMain.h"
#include "ofApp.h"
#include "ofAppiOSWindow.h"

int main() {
    ofAppiOSWindow * window = new ofAppiOSWindow();
    window->enableRendererES2();
    
	ofSetupOpenGL(window, 1024,768, OF_FULLSCREEN);
	ofRunApp(new ofApp);
}
