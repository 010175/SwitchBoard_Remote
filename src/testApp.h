#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"

#include <stdio.h>

#include <arpa/inet.h>
#include <netdb.h>
#include <sys/stat.h>
# include <ifaddrs.h>

#include "ofxOsc.h"
#include <string>

#include "ofxNetworkUtils.h";

using namespace std;
class testApp : public ofxiPhoneApp {
	
public:
	void setup();
	void update();
	void draw();
	void exit();
	
	void touchDown(float x, float y, int touchId, ofxMultiTouchCustomData *data);
	void touchMoved(float x, float y, int touchId, ofxMultiTouchCustomData *data);
	void touchUp(float x, float y, int touchId, ofxMultiTouchCustomData *data);
	void touchDoubleTap(float x, float y, int touchId, ofxMultiTouchCustomData *data);
	
	void lostFocus();
	void gotFocus();
	void gotMemoryWarning();
	void deviceOrientationChanged(int newOrientation);
	
	string			myIP;
	
	ofxOscSender	sender;
	ofxOscReceiver	receiver;
	
	vector<string>	switchboardProcessList;
	int				switchboardSelectedProcessIndex;
	int				switchboardTouchedProcessIndex;
	bool			touchIsDown;
	bool			scrolling;
	
	ofPoint			touchPoint;
	
	float			scrollOffset;
	float			velocity;
	
	ofxiPhoneKeyboard * keyboard;
	
	string			host;
	string			remote_host;
	
	ofTrueTypeFont  fontMedium;
	ofTrueTypeFont	fontMediumBold;
	ofTrueTypeFont  fontSmall;
	ofTrueTypeFont  fontBig;
	
	ofTrueTypeFont  fontMediumFixed;
	ofTrueTypeFont  fontSmallFixed;

	ofxNetworkUtils networkUtils;
	
	bool connected;
	int lastPingTime;
	
};

