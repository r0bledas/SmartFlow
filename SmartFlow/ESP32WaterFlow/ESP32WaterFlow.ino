// Interface Water Flow Sensor with ESP32 board
// ESP32 Dev Module
// ESP32 Development Board

// G 1/2 Water Flow Sensor
// Reference https://my.cytron.io/p-g-1-2-water-flow-sensor

#define FLOW_SENSOR_PIN 27
const char* ssid = "IZZI-60DE";
const char* password = "MHHAFMWd";
volatile byte pulseCount;
float calibrationFactor = 4.5;
unsigned long oldMillis = 0;
unsigned long interval = 1000;
float flowRate;
unsigned long totalMilliLitres;

void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);
  pinMode(FLOW_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), pulseCounter, FALLING);
  oldMillis = millis();
}

void loop() {
  if (millis() - oldMillis > interval) {
    // Divide the flow rate in litres / minute by 60 to determine how many pulses
    // (flowRate) come in the sensor in 1 second.
    // Convert to milliLitres.
    flowRate = ((1000.0 / (millis() - oldMillis)) * pulseCount) / calibrationFactor;

    // Add the milliLitres passed in this second to the cumulative totalMilliLitres.
    totalMilliLitres += flowRate * 1000;

    Serial.print("Flow rate: ");
    Serial.print(flowRate);
    Serial.print(" L/min\t");
    Serial.print("Output Liquid Quantity: ");
    Serial.print(totalMilliLitres);
    Serial.println(" mL");

    oldMillis = millis();
    pulseCount = 0;
  }
}