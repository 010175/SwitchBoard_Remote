
#include "testApp.h"

#define SENDER_PORT 5555
#define RECEIVER_PORT 4444

#define LIST_ELEMENT_HEIGHT 35.0f
#define LIST_TOP 120.0f

#define PING_INTERVAL 4000

using namespace std;
//--------------------------------------------------------------
void testApp::setup(){	
	
	ofSetLogLevel(OF_LOG_VERBOSE);
	
	iPhoneSetOrientation(OFXIPHONE_ORIENTATION_PORTRAIT);
	
	// initialize the accelerometer
	// ofxAccelerometer.setup();
	// touch events will be sent to testApp
	
	ofxMultiTouch.addListener(this);
	
	//iPhoneAlerts will be sent to this.
	ofxiPhoneAlerts.addListener(this);
	
	
	switchboardSelectedProcessIndex =	-1;
	switchboardTouchedProcessIndex	=	-1;
	
	touchIsDown =						false;
	scrolling =							false;
	
	touchPoint =						ofPoint(-1, -1);
	scrollOffset =						0.0f;
	velocity =							0.0f;
	
	networkUtils.init();
	
	host = networkUtils.getInterfaceBroadcastAddress(0);// get the first interface broadcast adress
	
	// start osc
	sender.setup(host,SENDER_PORT);
	receiver.setup(RECEIVER_PORT);
	
	printf("sender : %s:%i\n",host.c_str(),SENDER_PORT);
	
	// load fonts
	fontSmall.loadFont(ofToDataPath("Helvetica Neue Roman.ttf"),9,true,true,true);
	fontMedium.loadFont(ofToDataPath("Helvetica Neue Bold.ttf"),16,true,true,true);
	fontMediumBold.loadFont(ofToDataPath("Helvetica Neue Bold.ttf"),16,true,true,true);
	fontBig.loadFont(ofToDataPath("automat.ttf"),16,true,true,true);
	
	fontSmallFixed.loadFont(ofToDataPath("Courier New.ttf"),9,true,true,true);
	fontMediumFixed.loadFont(ofToDataPath("Courier New.ttf"),16,true,true,true);
	
	quitButtonRectangle = ofRectangle(ofGetWidth()-80, 40, 30, 30);
	resetButtonRectangle = ofRectangle(ofGetWidth()-40, 40, 30, 30);
	
	connected = false;
	lastPingTime= ofGetElapsedTimeMillis();
	
	//ofDisableSmoothing();
	ofEnableSmoothing();
	ofEnableAlphaBlending();
	ofBackground(74, 82, 90); // nice DF background color
}


//--------------------------------------------------------------
void testApp::update() {
	// ping switchboard
	
	if (!connected){
		int now = ofGetElapsedTimeMillis();
		
		if (now - lastPingTime > PING_INTERVAL) {
			ofxOscMessage m;
			m.setAddress( "/monolithe/ping" );
			m.addIntArg( 1 );
			sender.sendMessage( m );
			printf("ping\n");
			lastPingTime= ofGetElapsedTimeMillis();
		}
	}
	
	while(receiver.hasWaitingMessages()) {
		
		ofxOscMessage rm;
		receiver.getNextMessage(&rm);
		printf("osc received %s, %i argument(s)\n",rm.getAddress(), rm.getNumArgs());
		
		string a = rm.getAddress(); // work around for string compare !
		
		if (a == "/monolithe/pong") { 
			
			
			//printf("switchboard ip : %s\n", rm.getArgAsString(i));
			
			host = rm.getRemoteIp();
			
			if (!connected){ // 
				sender.setup(host,SENDER_PORT);
				// we have the remote ip adress, query processList
				ofxOscMessage sm;
				
				sm.setAddress( "/monolithe/getprocesslist" );
				sm.addIntArg( 1 );
				sender.sendMessage( sm );
			}
			connected = true;
		}
		
		if (a == "/monolithe/setprocesslist") { 
			//printf("osc received : processlist\n");
			
			if (host != rm.getRemoteIp()){ // reset host if changed
				host = rm.getRemoteIp();
				sender.setup(host,SENDER_PORT);
				printf("resetting host adress to %s \n", host.c_str());
			}
			
			switchboardProcessList.clear();
			
			for (int i= 0; i<rm.getNumArgs(); i++){
				printf("process %i : %s\n",i, rm.getArgAsString(i));
				switchboardProcessList.push_back(rm.getArgAsString(i));
			}
			
			// ask for current app index
			ofxOscMessage sm;
			
			sm.setAddress( "/monolithe/getprocessindex" );
			sm.addIntArg( 1 );
			sender.sendMessage( sm );
			
		}
		
		if (a == "/monolithe/setprocessindex") { 
			//printf("osc received : processindex\n");
			
			if (host != rm.getRemoteIp()){ // reset host if changed
				host = rm.getRemoteIp();
				sender.setup(host,SENDER_PORT);
				printf("resetting host adress to %s \n", host.c_str());
			}
			
			switchboardSelectedProcessIndex = rm.getArgAsInt32(0); // get first osc argument.		
		}
		
	}
	
}

//--------------------------------------------------------------
void testApp::draw() {
	ofSetColor(200, 200, 200);
	
	ofPushMatrix();
	ofTranslate(0.0f, scrollOffset, 0.0f);
	
	if (connected ){
		for (int i = 0; i< switchboardProcessList.size(); i++){
			
			if ((i==switchboardTouchedProcessIndex)&&touchIsDown&&(!scrolling)) {
				ofSetColor(150, 150, 150);
				fontMedium.drawString(switchboardProcessList[i].c_str(),10,LIST_TOP+(i*LIST_ELEMENT_HEIGHT));
				
				//ofCircle(touchPoint.x, touchPoint.y, 10);
			} else if (i==switchboardSelectedProcessIndex) {
				
				ofSetColor(255, 255, 255);
				fontMediumBold.drawString(switchboardProcessList[i].c_str(),10,LIST_TOP+(i*LIST_ELEMENT_HEIGHT));
			} else {
				
				ofSetColor(200, 200, 200);
				fontMedium.drawString(switchboardProcessList[i].c_str(),10,LIST_TOP+(i*LIST_ELEMENT_HEIGHT));
			}	
		}
	} else {
		int alpha = ((ofGetElapsedTimeMillis()/10)%255);
		ofSetColor(255, 255, 255,255-alpha);
		int stringWidth = fontMediumBold.getStringBoundingBox("Connecting", 0, 0).width;
		
		fontMediumBold.drawString("Connecting",(ofGetWidth()/2)-(stringWidth/2),(ofGetHeight()/2)+15);
	}
	
	ofPopMatrix();
	
	ofSetColor(0,0,0,127); // nice DF background color
	ofRect(0,0, ofGetWidth(), 80);
	
	ofSetColor(200, 200, 200);
	
	if ((switchboardTouchedProcessIndex==-1) && touchIsDown) ofSetColor(255, 255, 255);
	fontBig.drawString("Switchboard Remote",10,18);
	fontSmallFixed.drawString(networkUtils.getInterfaceAddress(0)+" <--> "+host,10,60);
	
	ofRect(quitButtonRectangle.x,quitButtonRectangle.y,quitButtonRectangle.width, quitButtonRectangle.height);
	ofRect(resetButtonRectangle.x,resetButtonRectangle.y,resetButtonRectangle.width, resetButtonRectangle.height);
	
}

//--------------------------------------------------------------
void testApp::exit() {
	
}


//--------------------------------------------------------------
void testApp::touchDown(float x, float y, int touchId, ofxMultiTouchCustomData *data){
	
	if (touchId!=0) return;
	
	scrolling = false;
	touchIsDown = true;
	touchPoint = ofPoint(x, y);
	velocity = 0.0f;
	
	if (pointInRectangle(touchPoint, quitButtonRectangle)){ // stop process
		switchboardTouchedProcessIndex = -2;
		return;
		
	} else if (pointInRectangle(touchPoint, resetButtonRectangle)){ // reset connection
		
		switchboardTouchedProcessIndex = -1;
		return;
	}
	
	for (int i = 0; i< switchboardProcessList.size(); i++){
		if ((y>LIST_TOP-LIST_ELEMENT_HEIGHT+(i*LIST_ELEMENT_HEIGHT)+scrollOffset) && (y<LIST_TOP+(i*LIST_ELEMENT_HEIGHT)+scrollOffset)){
			
			switchboardTouchedProcessIndex = i;
			break;
		}
	}
	
	
}

//--------------------------------------------------------------
void testApp::touchMoved(float x, float y, int touchId, ofxMultiTouchCustomData *data){
	
	if (touchId!=0) return;
	if (!connected) return;
	
	float scrollLenth = touchPoint.y-y;
	
	float tmpScrollOffset = scrollOffset - scrollLenth;
	
	// spring
	if (tmpScrollOffset>0) scrollLenth *= .25;
	
	int limit = -(LIST_TOP-LIST_ELEMENT_HEIGHT+((switchboardProcessList.size()+1)*LIST_ELEMENT_HEIGHT))+ofGetHeight();
	if (tmpScrollOffset < limit ) scrollLenth *= .25;
	
	scrolling = true;
	
	scrollOffset = scrollOffset - scrollLenth;
	
	touchPoint = ofPoint(x, y);
	
	velocity = scrollLenth;
	
}

//--------------------------------------------------------------
void testApp::touchUp(float x, float y, int touchId, ofxMultiTouchCustomData *data){
	
	if (touchId!=0) return;
	
	scrollOffset = fmax(scrollOffset,-(LIST_TOP-LIST_ELEMENT_HEIGHT+((switchboardProcessList.size()+1)*LIST_ELEMENT_HEIGHT))+ofGetHeight());
	scrollOffset =  fmin(scrollOffset,0.0f);
	
	touchIsDown = false;
	
	if (scrolling) return;
	
	if (pointInRectangle(ofPoint(x,y), quitButtonRectangle)&&(switchboardTouchedProcessIndex==-2)){
		switchboardSelectedProcessIndex = -1;
		printf("osc send : stop\n");
		
		ofxOscMessage m;
		m.setAddress( "/monolithe/stopprocess" );
		sender.sendMessage( m );
		
		return;
		
	} else if (pointInRectangle(ofPoint(x,y), resetButtonRectangle)&&(switchboardTouchedProcessIndex==-1)){
		
		connected = false; // unset connection flag to reset process list
		return;
	}
	
	for (int i = 0; i< switchboardProcessList.size(); i++){
		if ((y>LIST_TOP-LIST_ELEMENT_HEIGHT+(i*LIST_ELEMENT_HEIGHT)+scrollOffset) && (y<LIST_TOP+(i*LIST_ELEMENT_HEIGHT)+scrollOffset)){
			
			if (switchboardTouchedProcessIndex==i){
				
				switchboardSelectedProcessIndex = i;
				
				printf("osc send launch %i\n",i);
				
				ofxOscBundle b;
				
				ofxOscMessage sm1, sm2;
				
				sm1.setAddress( "/monolithe/launchprocess" );
				sm1.addIntArg(i);
				
				sm2.setAddress( "/monolithe/getprocessindex" );
				
				b.addMessage(sm1);
				b.addMessage(sm2);
				
				sender.sendBundle(b);
				
			}
			break;
		}
	}	
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(float x, float y, int touchId, ofxMultiTouchCustomData *data){
}

//--------------------------------------------------------------
void testApp::lostFocus() {
}

//--------------------------------------------------------------
void testApp::gotFocus() {
	
	connected=false; // unset connection flag to reset process list
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning() {
}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){
}
		
//--------------------------------------------------------------
bool testApp::pointInRectangle(ofPoint aPoint, ofRectangle aRectangle)
{
	return 
	(
	 (aPoint.x>=aRectangle.x)&&
	 (aPoint.x<=aRectangle.x+aRectangle.width)&&
	 (aPoint.y>=aRectangle.y)&&
	 (aPoint.y<=aRectangle.y+aRectangle.height)
	);
}