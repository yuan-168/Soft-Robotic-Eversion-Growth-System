#include <Wire.h>
#include "Adafruit_MPRLS.h"
#include <PID_v1.h>

#define RESET_PIN  -1  // set to any GPIO pin # to hard-reset on begin()
#define EOC_PIN    -1  // set to any GPIO pin to read end-of-conversion by pin

int Kp = 3.4; int Ki = 6 ;int Kd = 0.135;
double setPoint, driverIn, driverOut;
PID myPID(&driverIn, &driverOut, &setPoint, Kp, Ki, Kd, DIRECT);

Adafruit_MPRLS mpr = Adafruit_MPRLS(RESET_PIN, EOC_PIN);

void setup() {
  Serial.begin(115200);
  Serial.println("MPRLS Simple Test");
  if (! mpr.begin()) {
    Serial.println("Failed to communicate with MPRLS sensor, check wiring?");
    while (1) {
      delay(10);
    }
  }
  Serial.println("Found MPRLS sensor");

  setPoint = 160;//desired output
  myPID.SetMode(AUTOMATIC);
}

void loop() {
  driverIn = mpr.readPressure()/10; 
  myPID.Compute();
  analogWrite(A4,driverOut);
  Serial.print("Pressure (KPa): "); 
  Serial.println(driverIn);
}
