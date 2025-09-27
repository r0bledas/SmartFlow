# SmartFlow ESP32 Implementation Guide

## Required Hardware
- ESP32 development board (ESP32-WROOM or ESP32-WROVER recommended)
- Water flow sensor (YF-S201 or similar Hall effect sensor)
- Jumper wires
- Micro USB cable for programming
- Optional: Power supply for permanent installation (5V)

## Hardware Connections
1. Connect the water flow sensor to ESP32:
   - VCC/Red wire → 5V pin on ESP32
   - GND/Black wire → GND pin on ESP32
   - Signal/Yellow wire → GPIO pin 27 on ESP32 (can be changed in code)

2. Optional: Add an LED indicator
   - Connect an LED with appropriate resistor to GPIO pin 2

## Installation Position
- Install the flow sensor inline with your water pipe
- Ensure the sensor is installed in the correct flow direction (usually marked with an arrow)
- For whole-house monitoring, install after the main water valve
- For specific appliance monitoring, install on the supply line to that appliance

## Notes
- The YF-S201 sensor is rated for 1-30L/min flow rates
- Operating pressure: ≤1.75MPa
- Make sure all connections are properly sealed to prevent leaks