# Title     : R&S Waveform creation
# Reference : AppNote 1GP62 Sec4 pg 15
# Input file:
#    First non comment line is the sampling rate in Hz
#    Subsequent lines are IQ data
#        Format: I,Q
#        Values: Sqrt(I^2 + Q^2) < 1
#        Exampl: 0.34345435,-1.398283
#
import math
import time
import struct
import numpy as np

def CreateWv(fileIn):
    WaveWrit = fileIn.split(".")[0] + ".wv"
    print("CreateWv.py:" + WaveWrit)
    fin = open(fileIn, 'r')
    fot = open(WaveWrit, 'wb')
    date = time.strftime("%Y-%m-%d;%H:%M:%S")

    ###############################################################################
    # File Read
    ###############################################################################
    prevread = " "
    while 1:                                            # Comment Header Parse
        currread  = fin.readline().strip()
        if currread[:1] != "#":                         # If lines doesn't have "#"
            clock = currread                            # This line has clock
            comment = prevread[1:]                      # Previous line has Comment
            break
        prevread = currread

    IQArry = np.array([])
    IQArry = [line.strip().split(',') for line in fin]
    IQArry = np.asfarray(IQArry, float)
    samples = len(IQArry)
    fin.close()                                         # Close Input File

    ###############################################################################
    # Calculate RMS
    ###############################################################################
    SUM = 0
    MAX = 0
    for IQ in IQArry:
        SQR = pow(IQ[0], 2) + pow(IQ[1], 2)
        SUM += SQR
        if SQR > MAX:
            MAX = SQR

    RMS = 10 * math.log10(samples / SUM)
    MAX = 10 * math.log10(1 / MAX)

    print(f"  Comment:{comment}")
    print(f"  ClockRt:{clock}")
    print(f"  Samples:{samples}")
    print(f"  RMSValu:{RMS:.6f}")
    print(f"  MaxValu:{MAX:.6f}")

    ###############################################################################
    # File Header Write
    ###############################################################################
    fot.write("{TYPE: SMU-WV,0}".encode())                  # Type: No change needed.
    fot.write(f"{{COMMENT: {comment}}}".encode())           # Comment
    fot.write(f"{{DATE:{date}}}".encode())                  # Date:2005-11-25;12:33:51
    fot.write(f"{{CLOCK:{clock}}}".encode())                # Wavefm Clock
    fot.write(f"{{CLOCK MARKER: {clock}}}".encode())        # Marker Clock
    fot.write(f"{{LEVEL OFFS:{RMS:.4f},{MAX:.4f}}}".encode())# RMS,Peak
    fot.write(f"{{SAMPLES:{samples:d}}}".encode())          # NumSamples
    fot.write("{MARKER LIST 1: 0:1;20:0}".encode())         # MkrList MkrOnly
    fot.write("{MARKER LIST 2: 0:0}".encode())              # MkrList MkrOnly
    fot.write("{MARKER LIST 3: 0:0}".encode())              # MkrList MkrOnly
    fot.write("{MARKER LIST 4: 0:0}".encode())              # MkrList MkrOnly
    numBytes = 4 * samples + 1
    fot.write((f"{{WAVEFORM-{numBytes:d}: #").encode())     # Waveform = NumSamples * 4 + 1

    # ##############################################################################
    # File Data Write
    # IQData is a 2byte little edian integer
    # IQData = Round(Real * 32768)
    # ##############################################################################
    i = 0
    for IQ in IQArry:
        if (IQ[0] > 1) or (IQ[1] > 1):
            print(f"Error IQ > 1: {IQ[0]}, {IQ[1]}")
        data = int(round(IQ[0] * 32767))
        data = struct.pack('<h', data)                      # i:4byte h:2byte H:unsigned2byte
        fot.write(data)
        data = int(round(IQ[1] * 32767))
        data = struct.pack('<h', data)                      # i:4byte h:2byte H:unsigned2byet
        fot.write(data)
    fot.write("}".encode())
    fot.close()                                             # Close Output File

if __name__ == "__main__":
    filename    = "IQGen_1Tone_100MHz.env"
    Comment     = ""
    Clock       = 983040000
    CreateWv(filename)
