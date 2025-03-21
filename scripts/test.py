import serial
import time

# Open COM13 at 9600 baud
ser = serial.Serial(port='COM13', baudrate=9600, timeout=1)

# Give the port some time to settle (optional, but helpful)
time.sleep(1)

# Bytes to send
data = bytes([0x01, 0xAA, 0x55])

# Send the data
ser.write(data)
print(f"Sent: {[hex(b) for b in data]}")

# Close the port
ser.close()
