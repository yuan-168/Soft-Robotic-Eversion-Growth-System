#include <Dynamixel2Arduino.h>

// 使用 OpenRB150 控制板
#define DXL_SERIAL Serial1
#define DEBUG_SERIAL Serial

const int DXL_DIR_PIN = -1;
Dynamixel2Arduino dxl(DXL_SERIAL, DXL_DIR_PIN);
using namespace ControlTableItem;

const float DXL_PROTOCOL_VERSION = 2.0;

const uint8_t motor_ID = 3;
const int retract_velocity = 90;

void setup(){   
  // 初始化调试串口，波特率为 115200 bps
  DEBUG_SERIAL.begin(115200);
  
  // 初始化 Dynamixel 串口，波特率为 57600 bps，这必须与 Dynamixel 电机的波特率匹配
  dxl.begin(57600);
  
  // 设置 Dynamixel 通信协议版本为 2.0
  dxl.setPortProtocolVersion(DXL_PROTOCOL_VERSION);
  
  // 检查电机是否连接
  dxl.ping(motor_ID); 
  // 关闭电机扭矩
  dxl.torqueOff(motor_ID);
  // 设置电机工作模式为速度控制模式
  dxl.setOperatingMode(motor_ID, OP_VELOCITY);
  // 打开电机扭矩
  dxl.torqueOn(motor_ID);

  DEBUG_SERIAL.println("System Ready. Press 1 to start, 2 to stop.");
}

void loop(){
  // 检查是否有键盘输入
  if (DEBUG_SERIAL.available()) {
    char input = DEBUG_SERIAL.read();

    if (input == '1') {
      // 开始操作，设置电机速度
      dxl.torqueOn(motor_ID);
      dxl.setGoalVelocity(motor_ID, retract_velocity);
      DEBUG_SERIAL.println("Motor started.");
    } 
    else if (input == '2') {
      // 结束操作，停止电机
      dxl.torqueOff(motor_ID);
      DEBUG_SERIAL.println("Motor stopped.");
    }
  }
}
