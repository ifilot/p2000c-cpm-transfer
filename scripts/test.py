import serial
import time

# Open COM13 at 9600 baud
ser = serial.Serial(port='COM13', baudrate=9600, timeout=1)

# Give the port some time to settle (optional, but helpful)
time.sleep(1)

# Bytes to send
data = bytes([i for i in range(1,130)])

# Send the data
ser.write(data)
print(f"Sent: {[hex(b) for b in data]}")

# Close the port
ser.close()
