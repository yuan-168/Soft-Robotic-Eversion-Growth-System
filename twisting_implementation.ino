#include <RC100.h> 
RC100 Controller;
uint16_t RcvData = 0;

#include <Dynamixel2Arduino.h>
//if using OpenRB150
#define DXL_SERIAL Serial1
#define DEBUG_SERIAL Serial
const int DXL_DIR_PIN = -1;
Dynamixel2Arduino dxl(DXL_SERIAL, DXL_DIR_PIN);
using namespace ControlTableItem;
const float DXL_PROTOCOL_VERSION = 2.0;

const uint8_t twist_ID = 1;
const uint8_t retract_ID = 3;

const uint8_t twist_cycle = 5;
const uint8_t retract_velocity = 90;
double twist_CP, twist_DP, twist_initial, retract_CP, retract_DP, retract_initial;

void setup(){   
  // Use Serial to debug.
  DEBUG_SERIAL.begin(115200);
  // Set Port baudrate to 57600bps. This has to match with DYNAMIXEL baudrate.
  dxl.begin(57600);
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  
//  // Get DYNAMIXEL information
//  dxl.ping(twist_ID); 
//  dxl.torqueOff(twist_ID);
//  dxl.setOperatingMode(twist_ID, OP_EXTENDED_POSITION);//limit rotation angle
//  dxl.torqueOn(twist_ID);
//  dxl.writeControlTableItem(PROFILE_VELOCITY, twist_ID, 50);
  
  dxl.ping(retract_ID); 
  dxl.torqueOff(retract_ID);
  dxl.setOperatingMode(retract_ID,OP_VELOCITY);//limit rotation angle
  dxl.torqueOn(retract_ID);
  
  Controller.begin(2); 
}

void loop(){
  RcvData = 0;
  if (Controller.available()){
    RcvData = Controller.readData();

//  if(RcvData == (RC100_BTN_L)){
//    dxl.torqueOn(twist_ID);
//    twist_initial = dxl.getPresentPosition(twist_ID, UNIT_DEGREE);
//    twist_DP = twist_initial - twist_cycle*360;
//    dxl.setGoalPosition(twist_ID, twist_DP, UNIT_DEGREE);   
//    }  
//
//  if(RcvData == (RC100_BTN_R)){
//    dxl.torqueOn(twist_ID);
//    twist_initial = dxl.getPresentPosition(twist_ID, UNIT_DEGREE);
//    twist_DP = twist_initial + twist_cycle*360;
//    dxl.setGoalPosition(twist_ID, twist_DP, UNIT_DEGREE);   
//    }  

  if(RcvData == (RC100_BTN_U)){
    dxl.torqueOn(retract_ID);
    dxl.setGoalVelocity(retract_ID, retract_velocity); 
    }

  if(RcvData == (RC100_BTN_D)){
    dxl.torqueOn(retract_ID);
    dxl.setGoalVelocity(retract_ID, -retract_velocity); 
    }    
   
  if(RcvData == (RC100_BTN_1)){
    dxl.torqueOff(retract_ID);  
    dxl.torqueOff(twist_ID);  
    }  
  }
}
