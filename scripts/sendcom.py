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

# check that preamble is 12 bytes
assert len(data) == 12

# read filename
with open('../src/hex/hex.com', 'rb') as f:
    filedata = bytes(f.read())

# expand to 128 bytes
filedata += bytes([0x00] * (128 - len(filedata)))
    
# check that block is 128 bytes
assert len(filedata) == 128

# Send the data
ser.write(data)
ser.write(filedata)

# Close the port
ser.close()
