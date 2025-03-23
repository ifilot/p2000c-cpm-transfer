import serial
import time
import os
import struct

def main():    
    # read filename
    p = os.path.join('..', 'programs', 'games', 'zork', 'ZORK2.COM')
    
    send_file_to_p2000c(p)

def send_file_to_p2000c(p):
    with open(p, 'rb') as f:
        filedata = bytes(f.read())

    nrblocks = len(filedata) // 128 + (1 if len(filedata) % 128 != 0 else 0)
    filedata += bytes([0x00] * ((nrblocks * 128) - len(filedata)))
    print(nrblocks)
    
    # set header
    data = bytes([1])                                   # start byte
    data += bytes(convert_to_8_3_filename(p).encode('ascii'))   # filename
    data += bytes(struct.pack('<H', nrblocks))          # number of blocks
    
    # check that header is 14 bytes
    assert len(data) == 14
        
    # check that filesize matches number of blocks
    assert len(filedata) == (nrblocks * 128)
    
    # Open COM13 at 9600 baud
    ser = serial.Serial(port='COM13', baudrate=9600, timeout=None)
    
    # Give the port some time to settle (optional, but helpful)
    time.sleep(0.2)
    
    # Send the data
    ser.write(data)
    time.sleep(1) # small delay
    
    # Write blocks
    for ctr,i in enumerate(range(0, len(filedata), 128)):
        chunk = filedata[i:i+128]
        ser.write(chunk)
        res = ser.read(2)   # read acknowledge byte
        checksum = sum(chunk)%256
    
        print('%03i / %03i: %02X / %02X / %s' % (
            ctr,
            nrblocks,
            checksum,
            res[0],
            'ACK' if res[1] == 0x06 else 'NAC',
        ))
    
    # Close the port
    ser.close()

def convert_to_8_3_filename(path):
    """
    Given a path, extract the filename and convert that to CP/M 8+3
    format
    """
    
    base = os.path.basename(path)
    name, ext = os.path.splitext(base)
    
    name = name.upper()
    ext = ext.upper().lstrip('.')

    name_part = name[:8].ljust(8)
    ext_part = ext[:3].ljust(3)

    return name_part + ext_part

if __name__ == '__main__':
    main()