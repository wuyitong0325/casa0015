#include <Wire.h>
#include <ArduinoBLE.h>
#include "Adafruit_SGP30.h"

Adafruit_SGP30 sgp;

// ===== BLE UUID（和 Flutter 端保持一致）=====
const char* SERVICE_UUID = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
const char* CHAR_UUID    = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // Notify
// ==========================================

BLEService iaqService(SERVICE_UUID);

// 加了 raw 字段，JSON 更长，所以把最大长度调大
BLECharacteristic iaqNotifyChar(CHAR_UUID, BLENotify, 90);

unsigned long lastSendMs = 0;

void setup() {
  Serial.begin(115200);
  while (!Serial) { delay(10); }

  Wire.begin();

  // SGP30 init
  if (!sgp.begin()) {
    Serial.println("ERROR: SGP30 not found. Check wiring (SDA/SCL/3.3V/GND).");
    while (1) delay(100);
  }

  // ✅ 强制初始化 IAQ 算法（很关键）
  sgp.IAQinit();

  Serial.println("SGP30 initialized, IAQinit done.");

  // BLE init
  if (!BLE.begin()) {
    Serial.println("ERROR: BLE begin failed. Check board selection + core.");
    while (1) delay(100);
  }

  BLE.setLocalName("IAQ-SGP30");
  BLE.setDeviceName("IAQ-SGP30");
  BLE.setAdvertisedService(iaqService);

  iaqService.addCharacteristic(iaqNotifyChar);
  BLE.addService(iaqService);

  const char* initMsg = "{\"eco2\":0,\"tvoc\":0,\"rawH2\":0,\"rawEthanol\":0,\"t\":0}\n";
  iaqNotifyChar.writeValue((const unsigned char*)initMsg, strlen(initMsg));

  BLE.advertise();
  Serial.println("BLE advertising started. Device name: IAQ-SGP30");
  Serial.println("Warming up... (SGP30 may output 400/0 for a while)");
}

void loop() {
  BLE.poll();

  if (millis() - lastSendMs < 1000) return;
  lastSendMs = millis();

  // 1) 先读 IAQ（eCO2 / TVOC）
  bool okIAQ = sgp.IAQmeasure();

  // 2) 再读 RAW（rawH2 / rawEthanol）用于确认传感器真的在“动”
  bool okRaw = sgp.IAQmeasureRaw();

  if (!okIAQ) {
    Serial.println("{\"error\":\"IAQmeasure_failed\"}");
  }

  if (!okRaw) {
    Serial.println("{\"error\":\"IAQmeasureRaw_failed\"}");
  }

  uint16_t eco2 = okIAQ ? sgp.eCO2 : 0;
  uint16_t tvoc = okIAQ ? sgp.TVOC : 0;
  uint16_t rawH2 = okRaw ? sgp.rawH2 : 0;
  uint16_t rawEthanol = okRaw ? sgp.rawEthanol : 0;

  // 串口输出（你截图那种）
  Serial.print("eco2="); Serial.print(eco2);
  Serial.print(" tvoc="); Serial.print(tvoc);
  Serial.print(" rawH2="); Serial.print(rawH2);
  Serial.print(" rawEthanol="); Serial.print(rawEthanol);
  Serial.print(" t="); Serial.println(millis());

  // BLE Notify JSON（一行一条，末尾 \n）
  char buf[96];
  int n = snprintf(buf, sizeof(buf),
                   "{\"eco2\":%u,\"tvoc\":%u,\"rawH2\":%u,\"rawEthanol\":%u,\"t\":%lu}\n",
                   eco2, tvoc, rawH2, rawEthanol, (unsigned long)millis());

  // 注意：如果 n >= 90，说明 JSON 超长，会被截断（理论上不会）
  if (n > 0) {
    iaqNotifyChar.writeValue((const unsigned char*)buf, n);
  }
}
