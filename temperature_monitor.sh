#include <DHT11.h>

#define DHTPIN 2      // Pin where the DHT11 is connected

DHT11 dht(DHTPIN);

void setup() {
  Serial.begin(9600);
}

void loop() {
  delay(2000); // Adjust delay as needed
  float temperatureC = dht.readTemperature();
  // Check if temperature reading is valid
  if (!isnan(temperatureC)) {
    Serial.println(temperatureC);
  }
}
And now the shell scripting file where we have done further working on the raw data that we received from the Arduino device:
#!/bin/bash

SERIAL_PORT="/dev/ttyUSB0"  
stty -F "$SERIAL_PORT" 9600 cs8 -cstopb -parenb

OUTPUT_FILE="temp_log.txt"

LOWER_LIMIT=20  
UPPER_LIMIT=50

UNACCEPTABLE_LIMIT=3

unacceptable_count=0

while true; do
  delay=2
  temperature=$(head -n 1 < "$SERIAL_PORT")
 
  if [ -n "$temperature" ]; then
    echo "$(date +"%Y-%m-%d %H:%M:%S"),$temperature" >> "$OUTPUT_FILE"
   
    temperature_from_file=$(tail -n 1 "$OUTPUT_FILE" | cut -d',' -f2)
   
    echo "Temperature: $temperature_from_file °C"
   
    if (( $(echo "$temperature_from_file >= $LOWER_LIMIT" | bc -l) )) && \
       (( $(echo "$temperature_from_file <= $UPPER_LIMIT" | bc -l) )); then
      echo "Temperature within acceptable range."
      unacceptable_count=0
    else
      ((unacceptable_count++))
      echo "Temperature out of acceptable range!"
      if [ "$unacceptable_count" -ge "$UNACCEPTABLE_LIMIT" ]; then
        echo "Warning: Too many consecutive unacceptable temperatures! System shutting down in 3 seconds..."
        sleep "3"
        exit
      fi
    fi
  else
    echo "Error: Failed to read temperature"
  fi
  sleep "$delay"
done
