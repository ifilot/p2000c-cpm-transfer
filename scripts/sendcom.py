import serial
import time
import os

# Open COM13 at 9600 baud
ser = serial.Serial(port='COM13', baudrate=9600, timeout=None)

# Give the port some time to settle (optional, but helpful)
time.sleep(0.2)

# set start byte
data = bytes([1])

# set filename
data += bytes('HEX     COM'.encode('ascii'))
print(data)

# set number of blocks
nrblocks = 8
data += bytes([nrblocks,0x00]) # two blocks, low byte first

# check that preamble is 12 bytes
assert len(data) == 14

# read filename
with open('../src/hex/hex.com', 'rb') as f:
    filedata = bytes(f.read())

# expand to fixed number of blocks
filedata += bytes([0x00] * ((nrblocks * 128) - len(filedata)))
    
# check that block is 128 bytes
assert len(filedata) == (nrblocks * 128)

# Send the data
ser.write(data)
time.sleep(1) # small delay

# Write blocks
for i in range(0, len(filedata), 128):
    chunk = filedata[i:i+128]
    ser.write(chunk)
    res = ser.read(1)   # read acknowledge byte
    print(res)

# Close the port
ser.close()