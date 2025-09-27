#include <Arduino.h>
#include <WiFi.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

// Flow sensor configuration
const int FLOW_SENSOR_PIN = 27;
volatile long pulseCount = 0;
float flowRate = 0.0;
unsigned int flowMilliLiters = 0;
unsigned long totalMilliLiters = 0;
unsigned long oldTime = 0;

// Calibration factor for YF-S201 sensor (adjust as needed)
// This sensor produces approximately 4.5 pulses per second per liter/minute
const float calibrationFactor = 4.5;

// BLE configuration
#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"

BLEServer* pServer = NULL;
BLECharacteristic* pCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// WiFi configuration (uncomment and set these if using WiFi)
// const char* ssid = "YourWiFiName";
// const char* password = "YourWiFiPassword";
// const char* serverAddress = "192.168.1.x"; // Your phone's IP when testing locally
// const int serverPort = 3000;
// WiFiClient client;

// Callback class for BLE connection events
class ServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    }

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

// Interrupt service routine for flow meter pulses
void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

void setup() {
  Serial.begin(115200);
  
  // Initialize the flow sensor
  pinMode(FLOW_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), pulseCounter, FALLING);
  
  // Initialize BLE
  setupBLE();
  
  // Uncomment to use WiFi instead of or in addition to BLE
  // setupWiFi();
  
  Serial.println("SmartFlow ESP32 sensor node initialized!");
}

void setupBLE() {
  // Initialize BLE device
  BLEDevice::init("SmartFlow Meter");
  
  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new ServerCallbacks());
  
  // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Create a BLE Characteristic for flow data
  pCharacteristic = pService->createCharacteristic(
                      CHARACTERISTIC_UUID,
                      BLECharacteristic::PROPERTY_READ   |
                      BLECharacteristic::PROPERTY_WRITE  |
                      BLECharacteristic::PROPERTY_NOTIFY |
                      BLECharacteristic::PROPERTY_INDICATE
                    );
  
  // Create a BLE descriptor
  pCharacteristic->addDescriptor(new BLE2902());
  
  // Start the service
  pService->start();
  
  // Start advertising
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // helps with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  
  Serial.println("BLE service started, waiting for connections...");
}

// Uncomment if using WiFi
/*
void setupWiFi() {
  // Connect to WiFi network
  Serial.println();
  Serial.print("Connecting to ");
  Serial.println(ssid);
  
  WiFi.begin(ssid, password);
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println("");
  Serial.println("WiFi connected");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
}
*/

void loop() {
  // Calculate flow rate every second
  if ((millis() - oldTime) > 1000) {
    // Disable the interrupt while calculating flow rate
    detachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN));
    
    // Calculate flow rate in liters per minute
    flowRate = ((1000.0 / (millis() - oldTime)) * pulseCount) / calibrationFactor;
    
    // Reset the pulse counter
    pulseCount = 0;
    
    // Convert to milliliters per minute
    flowMilliLiters = (flowRate / 60) * 1000;
    
    // Add the milliliters passed in this second to the total
    totalMilliLiters += flowMilliLiters;
    
    // Print the flow rate for this second
    Serial.print("Flow rate: ");
    Serial.print(flowRate);
    Serial.print(" L/min, Volume: ");
    Serial.print(totalMilliLiters / 1000);
    Serial.println(" L");
    
    // Update the time for the next calculation
    oldTime = millis();
    
    // Send data via BLE if connected
    if (deviceConnected) {
      String flowData = String(flowRate) + "," + String(totalMilliLiters/1000);
      pCharacteristic->setValue(flowData.c_str());
      pCharacteristic->notify();
      Serial.println("Sent via BLE: " + flowData);
    }
    
    // Uncomment to send data via WiFi as well
    /*
    if (WiFi.status() == WL_CONNECTED) {
      sendDataViaWiFi();
    }
    */
    
    // Re-enable the interrupt
    attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), pulseCounter, FALLING);
  }
  
  // Handle BLE connection changes
  if (!deviceConnected && oldDeviceConnected) {
    delay(500); // Give time for BLE stack to get ready
    pServer->startAdvertising(); // Restart advertising
    Serial.println("BLE: Start advertising");
    oldDeviceConnected = deviceConnected;
  }
  
  if (deviceConnected && !oldDeviceConnected) {
    // Do stuff when newly connected
    oldDeviceConnected = deviceConnected;
    Serial.println("BLE: New device connected");
  }
  
  delay(10); // Small delay for stability
}

// Uncomment if using WiFi
/*
void sendDataViaWiFi() {
  if (client.connect(serverAddress, serverPort)) {
    String postData = "{\"flow_rate\":" + String(flowRate) + ",\"total_volume\":" + String(totalMilliLiters/1000) + "}";
    
    client.println("POST /api/flow_data HTTP/1.1");
    client.println("Host: " + String(serverAddress));
    client.println("Content-Type: application/json");
    client.print("Content-Length: ");
    client.println(postData.length());
    client.println("Connection: close");
    client.println();
    client.println(postData);
    
    Serial.println("Data sent via WiFi");
    
    // Read and print the server response
    while (client.available()) {
      String line = client.readStringUntil('\r');
      Serial.print(line);
    }
    
    client.stop();
  } else {
    Serial.println("Failed to connect to server");
  }
}
*/