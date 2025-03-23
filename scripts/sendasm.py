import serial
import time

ser = serial.Serial('COM13', 9600)

with open('../src/transblock/transblock.asm') as f:
    for line in f:
        line = line.rstrip('\n') + '\r\n'  # force CP/M-style line endings
        ser.write(line.encode('ascii'))
        time.sleep(0.001)

# Send EOF marker expected by PIP
ser.write(b'\x1A')  # Ctrl+Z
ser.close()