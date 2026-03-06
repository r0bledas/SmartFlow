# SmartFlow Calibration Guide 🔧

## Quick Calibration Instructions

### What You Did:
- **Actual water poured**: 100ml (600ml → 500ml in bottle)
- **Sensor reading**: 10,212ml (102.12× too high)
- **Previous calibration factor**: 4.5
- **New calibration factor**: **459.54**

---

## Steps to Apply the New Calibration

### 1. Upload the Updated Code
1. Open the ESP32WaterFlow.ino file in Arduino IDE
2. The calibration factor has been updated to **459.54**
3. Upload the code to your ESP32 board
4. Wait for the board to reboot and reconnect to WiFi

### 2. Reset the Counter
- In the SmartFlow app, go to Settings
- Disconnect and reconnect to the ESP32
- Or use the reset button on the Home screen

### 3. Test the Calibration
1. **Prepare a measured amount of water**:
   - Use a measuring cup or graduated cylinder
   - Recommended: 500ml or 1000ml for accuracy
   
2. **Pour water through the sensor**:
   - Pour at a steady, moderate speed
   - Don't pour too fast or too slow
   
3. **Check the reading**:
   - The app should display a value very close to what you poured
   - Example: Pour 500ml → App should show ~0.5L (500ml)

### 4. Fine-Tune if Needed

If the reading is still off, calculate a new factor:

```
New Calibration Factor = Current Factor × (Sensor Reading / Actual Amount)
```

**Example:**
- Current factor: 459.54
- You poured: 500ml
- Sensor read: 520ml
- New factor = 459.54 × (520 / 500) = 477.52

---

## Understanding the Calibration Factor

The calibration factor represents **pulses per liter** for your specific sensor.

### Formula in the code:
```cpp
flowRate = ((1000.0 / (millis() - oldMillis)) * pulseCount) / calibrationFactor;
```

- **Higher calibration factor** = Lower readings (use if sensor reads too high)
- **Lower calibration factor** = Higher readings (use if sensor reads too low)

---

## Common G1/2 Water Flow Sensor Calibration Factors

Different batches and models vary:
- **Typical range**: 400-500 pulses/liter
- **Your sensor**: 459.54 pulses/liter
- **Standard (datasheet)**: 450 pulses/liter

---

## Troubleshooting

### Readings Still Too High?
- Increase the calibration factor
- Check for air bubbles in the sensor
- Ensure water flows smoothly through the sensor

### Readings Still Too Low?
- Decrease the calibration factor
- Check that the sensor impeller spins freely
- Verify the sensor is installed in the correct direction (arrow on sensor body)

### Unstable Readings?
- Pour at a consistent speed
- Make sure the sensor is mounted securely
- Check wire connections to GPIO 27

### No Readings at All?
- Verify sensor is connected to GPIO 27
- Check the sensor's power supply
- Test with the Serial Monitor (115200 baud) to see raw pulse counts

---

## Advanced: Finding the Perfect Calibration

For the most accurate calibration:

1. **Reset the counter** in the app
2. **Pour exactly 1000ml** (1 liter) through the sensor at moderate speed
3. **Note the sensor reading** in the app
4. **Calculate**: `New Factor = 459.54 × (Sensor Reading / 1000)`
5. **Update the code** with the new factor
6. **Upload and test again**

### Multiple Test Average Method:
1. Do 3-5 tests with 500ml or 1000ml
2. Average the readings
3. Calculate the correction factor from the average
4. This gives more consistent results

---

## Quick Reference

| What You Pour | What App Should Show |
|---------------|----------------------|
| 100ml         | 0.1L                 |
| 250ml         | 0.25L                |
| 500ml         | 0.5L                 |
| 1000ml (1L)   | 1.0L                 |

---

## Current Settings

**Calibration Factor**: 459.54  
**Sensor Model**: G1/2 Water Flow Sensor  
**GPIO Pin**: 27  
**Last Updated**: October 30, 2025

---

## Notes

- The calibration factor may vary slightly with flow rate
- For best accuracy, calibrate at the flow rate you'll typically use
- Temperature can affect sensor accuracy slightly
- Re-calibrate if you notice drift over time

