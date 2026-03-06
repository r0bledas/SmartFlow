// SmartFlow ESP32 Water Flow Monitor
// With BLE WiFi Provisioning — no hardcoded credentials needed
// Users configure WiFi from the SmartFlow iOS app

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Preferences.h>

// ===================== PIN & SENSOR CONFIG =====================
#define FLOW_SENSOR_PIN 27

// ===================== BLE UUIDs =====================
#define SERVICE_UUID              "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define WIFI_SSID_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a9"
#define WIFI_PASS_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26aa"
#define WIFI_STATUS_CHAR_UUID     "beb5483e-36e1-4688-b7f5-ea07361b26ab"
#define FLOW_DATA_CHAR_UUID       "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// ===================== GLOBALS =====================
Preferences preferences;
WebServer server(80);

// Flow sensor
volatile byte pulseCount = 0;
float calibrationFactor = 459.54;
unsigned long oldMillis = 0;
float flowRate = 0;
unsigned long totalMilliLitres = 0;

// BLE
BLEServer* pServer = NULL;
BLECharacteristic* pStatusChar = NULL;
bool bleActive = false;

// WiFi credentials from BLE
String rxSSID = "";
String rxPass = "";
bool credentialsReady = false;  // Flag — set by BLE callback, handled by loop()

// ===================== INTERRUPT =====================
void IRAM_ATTR pulseCounter() {
  pulseCount++;
}

// ===================== BLE CALLBACKS =====================
class MyServerCB : public BLEServerCallbacks {
  void onConnect(BLEServer* s) {
    Serial.println("BLE: Client connected");
  }
  void onDisconnect(BLEServer* s) {
    Serial.println("BLE: Client disconnected");
    if (bleActive) {
      delay(500);
      s->startAdvertising();
    }
  }
};

class SSIDWriteCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    rxSSID = String(c->getValue().c_str());
    Serial.println("BLE: Got SSID: " + rxSSID);
  }
};

class PassWriteCB : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* c) {
    rxPass = String(c->getValue().c_str());
    Serial.println("BLE: Got password (len=" + String(rxPass.length()) + ")");
    // Just set the flag — loop() will handle save & restart safely
    if (rxSSID.length() > 0 && rxPass.length() > 0) {
      credentialsReady = true;
    }
  }
};

// ===================== BLE SETUP =====================
void startBLE() {
  Serial.println("BLE: Starting...");
  bleActive = true;

  BLEDevice::init("SmartFlow");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCB());

  BLEService* svc = pServer->createService(SERVICE_UUID);

  // SSID characteristic (write)
  BLECharacteristic* ssidC = svc->createCharacteristic(
    WIFI_SSID_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  ssidC->setCallbacks(new SSIDWriteCB());

  // Password characteristic (write)
  BLECharacteristic* passC = svc->createCharacteristic(
    WIFI_PASS_CHAR_UUID, BLECharacteristic::PROPERTY_WRITE);
  passC->setCallbacks(new PassWriteCB());

  // Status characteristic (read + notify)
  pStatusChar = svc->createCharacteristic(
    WIFI_STATUS_CHAR_UUID,
    BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY);
  pStatusChar->addDescriptor(new BLE2902());
  pStatusChar->setValue("0");

  svc->start();

  BLEAdvertising* adv = BLEDevice::getAdvertising();
  adv->addServiceUUID(SERVICE_UUID);
  adv->setScanResponse(true);
  BLEDevice::startAdvertising();

  Serial.println("BLE: Advertising — open SmartFlow app to configure WiFi");
}

// ===================== HTTP SERVER =====================
void startHTTP() {
  server.on("/", handleRoot);
  server.on("/flow", handleFlow);
  server.on("/reset", handleReset);
  server.on("/clearwifi", handleClear);
  server.enableCORS(true);
  server.begin();
  Serial.println("HTTP: Server started at " + WiFi.localIP().toString());
}

void handleRoot() {
  String h = "<!DOCTYPE html><html><head><title>SmartFlow</title>"
    "<meta name='viewport' content='width=device-width,initial-scale=1'>"
    "<style>body{font-family:Arial;margin:20px;background:#f0f0f0}"
    ".c{background:#fff;padding:20px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,.1)}"
    ".m{background:#e3f2fd;padding:15px;margin:10px 0;border-radius:5px;text-align:center}"
    ".v{font-size:24px;font-weight:bold;color:#1976d2}.l{font-size:14px;color:#666}"
    "button{background:#1976d2;color:#fff;padding:10px 20px;border:none;border-radius:5px;cursor:pointer;margin:5px}"
    ".d{background:#d32f2f}</style></head><body><div class='c'>"
    "<h1>🌊 SmartFlow</h1>"
    "<div class='m'><div class='v'>" + String(flowRate, 2) + " L/min</div><div class='l'>Flow Rate</div></div>"
    "<div class='m'><div class='v'>" + String(totalMilliLitres) + " mL</div><div class='l'>Total Volume</div></div>"
    "<div class='m'><div class='v'>" + WiFi.localIP().toString() + "</div><div class='l'>IP Address</div></div>"
    "<div style='text-align:center;margin-top:20px'>"
    "<button onclick=\"fetch('/reset').then(()=>location.reload())\">Reset</button>"
    "<button onclick=\"window.open('/flow')\">JSON</button>"
    "<button class='d' onclick=\"if(confirm('Clear WiFi and restart?'))fetch('/clearwifi').then(()=>alert('Restarting...'))\">Factory Reset</button>"
    "</div></div></body></html>";
  server.send(200, "text/html", h);
}

void handleFlow() {
  StaticJsonDocument<256> doc;
  doc["flowRate"] = flowRate;
  doc["totalMilliLitres"] = (int)totalMilliLitres;
  doc["timestamp"] = millis();
  doc["status"] = "connected";
  doc["ip"] = WiFi.localIP().toString();
  String r;
  serializeJson(doc, r);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", r);
}

void handleReset() {
  totalMilliLitres = 0;
  flowRate = 0;
  StaticJsonDocument<128> doc;
  doc["message"] = "reset";
  doc["totalMilliLitres"] = 0;
  String r;
  serializeJson(doc, r);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", r);
  Serial.println("Counter reset");
}

void handleClear() {
  preferences.begin("wifi", false);
  preferences.clear();
  preferences.end();
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", "WiFi cleared. Restarting...");
  Serial.println("WiFi credentials cleared");
  delay(1000);
  ESP.restart();
}


// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(1000);  // Give Serial time to connect

  Serial.println("\n=== SmartFlow ESP32 ===");

  pinMode(FLOW_SENSOR_PIN, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(FLOW_SENSOR_PIN), pulseCounter, FALLING);

  // Check saved credentials
  preferences.begin("wifi", true);
  String savedSSID = preferences.getString("ssid", "");
  String savedPass = preferences.getString("pass", "");
  preferences.end();

  if (savedSSID.length() > 0) {
    Serial.println("Found saved WiFi: " + savedSSID);

    WiFi.mode(WIFI_STA);
    WiFi.begin(savedSSID.c_str(), savedPass.c_str());
    for (int i = 0; i < 20; i++) {
      if (WiFi.status() == WL_CONNECTED) break;
      delay(500);
      Serial.print(".");
    }

    if (WiFi.status() == WL_CONNECTED) {
      Serial.println("\nWiFi: Connected! IP=" + WiFi.localIP().toString());
      startHTTP();
      oldMillis = millis();
      return;  // Normal mode — skip BLE
    }

    Serial.println("\nWiFi: Saved credentials failed");
    WiFi.disconnect();
  } else {
    Serial.println("No saved WiFi credentials");
  }

  // Start BLE provisioning
  startBLE();
  oldMillis = millis();
}

// ===================== LOOP =====================
void loop() {
  if (bleActive) {
    // Check if BLE callback received credentials
    if (credentialsReady) {
      credentialsReady = false;
      Serial.println("Saving credentials for: " + rxSSID);

      // Save to flash (safe from main loop context)
      preferences.begin("wifi", false);
      preferences.putString("ssid", rxSSID);
      preferences.putString("pass", rxPass);
      preferences.end();
      Serial.println("Credentials saved — restarting into WiFi mode...");

      delay(500);
      ESP.restart();
    }
  } else {
    server.handleClient();

    if (millis() - oldMillis > 1000) {
      flowRate = ((1000.0 / (millis() - oldMillis)) * pulseCount) / calibrationFactor;
      totalMilliLitres += flowRate * 1000;
      oldMillis = millis();
      pulseCount = 0;
    }
  }
}
