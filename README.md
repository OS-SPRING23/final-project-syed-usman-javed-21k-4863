# Plant Monitoring Script

This Bash script monitors the environment for a plant by reading values from an LDR (Light-Dependent Resistor) sensor and a DHT11 temperature and humidity sensor. It provides warnings and notifications based on the readings to ensure the well-being of the plant.

## Requirements

- Raspberry Pi 2B
- LDR sensor connected to GPIO pin 4
- DHT11 sensor connected to GPIO pin 17
- Adafruit DHT library for Python

## Usage

1. Make sure the required hardware is properly connected to the Raspberry Pi.
2. Install the Adafruit DHT library for Python.
3. Execute the script using the following command:

```bash
$ bash plant_monitoring.sh
```

## Configuration

- `GPIO_PIN_LDR`: GPIO pin number for the LDR sensor.
- `GPIO_PIN_DHT`: GPIO pin number for the DHT11 sensor.
- `PEAK_TEMPERATURE`: Threshold temperature value for triggering a warning.
- `PEAK_HUMIDITY_LOW`: Minimum threshold humidity value for triggering a low humidity warning.
- `PEAK_HUMIDITY_MAX`: Maximum threshold humidity value for triggering a high humidity warning.
- `SAFE_DIFFERNCE_FROM_LAST_SUNLIGHT_DETECTED_SECONDS`: Threshold time difference in seconds for detecting a lack of sunlight.

## Cleanup

To stop the script and clean up the GPIO resources, press `Ctrl+C`.

## License

This project is licensed under the [MIT License](LICENSE).

