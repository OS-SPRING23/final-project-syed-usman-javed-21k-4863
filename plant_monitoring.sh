#!/bin/bash

# Define the GPIO pin number
GPIO_PIN_LDR=4
GPIO_PIN_DHT=17

## General Code
# Function to handle keyboard interrupt
function keyboard_interrupt {
    echo "Keyboard interrupt detected. Cleaning up."
    # Clean up
    echo "$GPIO_PIN_LDR" > /sys/class/gpio/unexport
    # No need for cleanup for DHT, as Adafruit library handles it automatically
    echo "Goodbye, take good care of your plant."
    exit 0
}
# Trap the keyboard interrupt signal
trap keyboard_interrupt SIGINT

## Code for LDR
# Assign variables
# Assuming that last sunlight was received when code started
LAST_SUNLIGHT_RECEIVED=$(date +%r)
# Set the GPIO pin as input
echo "$GPIO_PIN_LDR" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$GPIO_PIN_LDR/direction
# Function to read the sensor value
read_ldr_value() {
    local gpio_value=$(cat /sys/class/gpio/gpio$GPIO_PIN_LDR/value)
    echo $gpio_value
}
echo_receiving_sunlight_human_readable() {
    local local_ldr_value=$1

    if [[ local_ldr_value -eq 1 ]]; then
        echo "Receiving sunlight: Yes"
    elif [[ local_ldr_value -eq 0 ]]; then
        echo "Receiving sunlight: No"
    fi
}

## Code for DHT
# Assign threshold variables
PEAK_TEMPERATURE=40
PEAK_HUMIDITY_LOW=20
PEAK_HUMIDITY_MAX=90
SAFE_DIFFERNCE_FROM_LAST_SUNLIGHT_DETECTED_SECONDS=300 # 300 seconds is 5 minutes

## Main loop
while true; do
    # Read the LDR sensor's value using pure bash script
    ldr_value=$(read_ldr_value)
    # Inverting the value, as sensor is giving 0 on light and 1 on dark
    # We want 1 on light and 0 on dark, for ease of use
    if [[ ldr_value -eq 1 ]]; then
        ldr_value=0
    else
        ldr_value=1
    fi
    # Read the temperature and humidity using Python and the Adafruit DHT library
    TEMP_HUMIDITY=$(python3 - <<EOF
import Adafruit_DHT

sensor = Adafruit_DHT.DHT11
pin = $GPIO_PIN_DHT

humidity, temperature = Adafruit_DHT.read_retry(sensor, pin)

# print(f'Temperature: {temperature:.1f} °C')
# print(f'Humidity: {humidity:.1f}%')

print(temperature)
print(humidity)
EOF
    )
    # Assign the values to separate variables
    temperature=$(echo "$TEMP_HUMIDITY" | sed -n 1p)
    humidity=$(echo "$TEMP_HUMIDITY" | sed -n 2p)

    # Print the temperature and humidity
    echo "Temperature: $temperature °C"
    echo "Humidity: $humidity%"

    # Print the LDR sensor value
    # echo "LDR value: $ldr_value"
    echo_receiving_sunlight_human_readable $ldr_value

    ####################

    current_time=$(date +%r)
    
    if [[ $ldr_value -eq 1 ]]; then
        LAST_SUNLIGHT_RECEIVED=$current_time
    fi

    # Converting to timestamps to calculate time_differnece
    last_sunlight_timestamp=$(date -d "$LAST_SUNLIGHT_RECEIVED" +%s)
    current_timestamp=$(date -d "$current_time" +%s)
    time_difference=$((current_timestamp - last_sunlight_timestamp))

    if [[ time_difference -gt SAFE_DIFFERNCE_FROM_LAST_SUNLIGHT_DETECTED_SECONDS ]]; then
        echo "Warning: Last sunlight received more than your set threshold!"
        echo "Please make sure that your plant has access to adequate sunlight."
    fi

    # Convert temperature and humidity to integer values by removing decimal part
    temperature_int=${temperature%.*}
    humidity_int=${humidity%.*}

    if [[ $(bc <<< "$humidity_int > $PEAK_HUMIDITY_MAX") == 1 ]]; then
        echo "Warning: Move your plant under sunlight, the humidity level has reached more than your set threshold."
    elif [[ $(bc <<< "$humidity_int < $PEAK_HUMIDITY_LOW") == 1 ]]; then
        echo "Warning: Humidity level is very low, turning on sprinklers."
    fi

    if [[ $(bc <<< "$temperature_int > $PEAK_TEMPERATURE") == 1 ]]; then
        echo "Warning: Room Temperature has increased than set temperature threshold."
        echo "Please move your plant to a cooler place."
    fi

    ####################

    sleep 1

done