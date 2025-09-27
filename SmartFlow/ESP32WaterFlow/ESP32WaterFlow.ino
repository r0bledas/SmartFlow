// Interface Water Flow Sensor with ESP32 board
// ESP32 Dev Module
// ESP32 Development Board

// G 1/2 Water Flow Sensor
// Reference https://my.cytron.io/p-g-1-2-water-flow-sensor

#include <WiFi.h>
#include <WebServer.h>
#include <ArduinoJson.h>

#define FLOW_SENSOR_PIN 27

// Wi-Fi credentials - UPDATE THESE WITH YOUR NETWORK
const char* ssid = "IZZI-60DE";
const char* password = "MHHAFMWd";

// Web server on port 80
WebServer server(80);

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
  
  // Connect to Wi-Fi
  WiFi.begin(ssid, password);
  Serial.print("Connecting to WiFi");
  
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  
  Serial.println();
  Serial.println("WiFi connected!");
  Serial.print("IP address: ");
  Serial.println(WiFi.localIP());
  
  // Setup web server routes
  server.on("/", handleRoot);
  server.on("/flow", handleFlowData);
  server.on("/reset", handleReset);
  server.enableCORS(true);
  
  server.begin();
  Serial.println("HTTP server started");
  Serial.println("Use this IP in your SmartFlow app: " + WiFi.localIP().toString());
}

void loop() {
  server.handleClient();
  
  if (millis() - oldMillis > interval) {
    // Calculate flow rate
    flowRate = ((1000.0 / (millis() - oldMillis)) * pulseCount) / calibrationFactor;
    
    // Add the milliLitres passed in this second to the cumulative total
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

void handleRoot() {
  String html = "<!DOCTYPE html><html><head><title>ESP32 Water Flow Monitor</title>";
  html += "<meta name='viewport' content='width=device-width, initial-scale=1'>";
  html += "<style>body{font-family:Arial;margin:40px;background:#f0f0f0}";
  html += ".container{background:white;padding:20px;border-radius:10px;box-shadow:0 2px 10px rgba(0,0,0,0.1)}";
  html += ".metric{background:#e3f2fd;padding:15px;margin:10px 0;border-radius:5px;text-align:center}";
  html += ".value{font-size:24px;font-weight:bold;color:#1976d2}";
  html += ".label{font-size:14px;color:#666;margin-top:5px}";
  html += "button{background:#1976d2;color:white;padding:10px 20px;border:none;border-radius:5px;cursor:pointer;margin:5px}";
  html += "button:hover{background:#1565c0}</style></head>";
  html += "<body><div class='container'>";
  html += "<h1>🌊 SmartFlow ESP32 Monitor</h1>";
  html += "<div class='metric'><div class='value'>" + String(flowRate, 2) + " L/min</div><div class='label'>Flow Rate</div></div>";
  html += "<div class='metric'><div class='value'>" + String(totalMilliLitres) + " mL</div><div class='label'>Total Volume</div></div>";
  html += "<div class='metric'><div class='value'>" + WiFi.localIP().toString() + "</div><div class='label'>Device IP Address</div></div>";
  html += "<div style='text-align:center;margin-top:20px'>";
  html += "<button onclick=\"fetch('/reset').then(()=>location.reload())\">Reset Counter</button>";
  html += "<button onclick=\"window.open('/flow', '_blank')\">View JSON Data</button>";
  html += "</div>";
  html += "<p style='color:#666;text-align:center;margin-top:20px'>Connected to SmartFlow App</p>";
  html += "</div></body></html>";
  
  server.send(200, "text/html", html);
}

void handleFlowData() {
  // Create JSON response exactly matching your app's FlowData structure
  DynamicJsonDocument doc(1024);
  doc["flowRate"] = flowRate;
  doc["totalMilliLitres"] = (int)totalMilliLitres;
  doc["timestamp"] = millis();
  doc["status"] = "connected";
  
  String response;
  serializeJson(doc, response);
  
  // Add CORS headers for web browser compatibility
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  
  server.send(200, "application/json", response);
  
  // Debug output
  Serial.println("Data sent to SmartFlow app: " + response);
}

void handleReset() {
  totalMilliLitres = 0;
  flowRate = 0;
  
  DynamicJsonDocument doc(512);
  doc["message"] = "Counter reset successfully";
  doc["totalMilliLitres"] = 0;
  doc["flowRate"] = 0.0;
  doc["timestamp"] = millis();
  
  String response;
  serializeJson(doc, response);
  
  // Add CORS headers
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", response);
  
  Serial.println("Counter reset by SmartFlow app");
}
