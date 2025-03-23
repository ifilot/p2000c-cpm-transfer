import serial
import time
import os
import struct

def main():    
    p = os.path.join('..', 'programs', 'games', 'zork', 'ZORK3.COM')
    
    send_file_to_p2000c(p)

def send_file_to_p2000c(p):
    """
    Transfers a binary file over serial using a custom protocol.
    
    Steps:
    1. Opens the specified file in binary mode and reads its contents.
    2. Pads the file to a multiple of 128 bytes.
    3. Calculates the number of 128-byte blocks.
    4. Constructs a 14-byte header:
       - Start byte (0x01)
       - 8.3 UPPERCASE filename (11 bytes, space-padded)
       - 2-byte little-endian block count
    5. Opens a serial port (COM13 @ 9600 baud) for transmission.
    6. Sends the header and then the file in 128-byte chunks.
    7. After each chunk, waits for a 2-byte response:
       - First byte: checksum (should match calculated checksum)
       - Second byte: 0x06 (ACK) or other (NAC)
    8. Prints transfer progress with block index, checksum, response, and status.
    
    Raises:
    - AssertionError if header size is not 14 bytes or file size mismatch occurs.
    """
    with open(p, 'rb') as f:
        filedata = bytes(f.read())

    nrblocks = len(filedata) // 128 + (1 if len(filedata) % 128 != 0 else 0)
    filedata += bytes([0x00] * ((nrblocks * 128) - len(filedata)))
    
    # set header
    data = bytes([1])                                           # start byte
    data += bytes(convert_to_8_3_filename(p).encode('ascii'))   # filename
    data += bytes(struct.pack('<H', nrblocks))                  # number of blocks
    
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