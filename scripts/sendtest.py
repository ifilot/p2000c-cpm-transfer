import serial
import time
import os

# Open COM13 at 9600 baud
ser = serial.Serial(port='COM13', baudrate=9600, timeout=1)

# Give the port some time to settle (optional, but helpful)
time.sleep(0.2)

# set start byte
data = bytes([1])

# set filename
data += bytes('HEX     COM'.encode('ascii'))
print(data)

data += bytes([0xAA, 0x55])

# check that preamble is 12 bytes
assert len(data) == 14

# Send the data
ser.write(data)

# Close the port
ser.close()