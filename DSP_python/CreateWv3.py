#*****************************************************************
# Title: R&S Waveform creation
#
# Reference: 
#   AppNote 1GP62 Sec4 pg 15
#
# Instr:
#   SGT-Modulated VSG
#   SMW-Modulated VSG
#
# Input file:
#    Header
#      Comment line begins with "#"
#      Script will ignore initial lines w/ #
#      Last Comment line will be used in *.wv
#   First non comment line is the sampling rate in Hz
#   Subsequent lines are IQ data
#      Format: I,Q
#      Values: Sqrt(I^2 + Q^2) < 1
#      Exampl: 0.34345435,-1.398283
#
#   Sample File:
#      # This file is ready for convertion
#      # Waveform created by Rohde & Schwarz
#      # Please put *.wv comment here
#      15360000
#      -0.1800899164,-0.0500845546
#      -0.0804992785,0.1618766459
#      -0.0390753583,0.1214229520
#      0.0361018054,0.1222110829
#      0.1565244489,-0.0252769231
#      ...
#      0.0236197484,-0.1661472281
#
#*****************************************************************
# User Input Settings
#*****************************************************************
WaveRead = "CreateWv.env"
Comment = ""                                 #Read from input file
Clock = 983040000                            #Read from input file

#*****************************************************************
# Code Start
#*****************************************************************
import math
import time
import struct
import numpy as np

WaveWrit = WaveRead.split(".")[0] + ".wv"
print("CreateWv.py:" + WaveWrit)
fin = open(WaveRead, 'r')
fot = open(WaveWrit, 'wb')
date = time.strftime("%Y-%m-%d;%H:%M:%S")

#*****************************************************************
# File Read
#*****************************************************************
prevread=" "
while 1:                                     #Comment Header Parse
   currread  = fin.readline().strip()
   if currread[:1] != "#":                   #If lines doesn't have "#"
      clock = currread                       #This line has clock
      comment = prevread[1:]                 #Previous line has Comment
      break
   prevread = currread

IQArry = np.array([])
IQArry = [line.strip().split(',') for line in fin]
IQArry = np.asfarray(IQArry,float)
samples = len(IQArry)
fin.close()                                  #Close Input File

#*****************************************************************
# Calculate RMS
#*****************************************************************
RMS = 0
MAX = 0
for IQ in IQArry:
   SQR = pow(IQ[0],2)+pow(IQ[1],2)
   RMS += SQR
   if SQR > MAX:
      MAX = SQR

RMS = 10*math.log10(samples/RMS)
MAX = 10*math.log10(1/MAX)
   
print("  Comment:%s"%comment)
print("  ClockRt:%s"%clock)
print("  Samples:%d"%samples)
print("  RMSValu:%f"%RMS)
print("  MaxValu:%f"%MAX)

#*****************************************************************
# File Header Write
#*****************************************************************
fot.write("{TYPE: SMU-WV,0}".encode())                   #Type: No change needed.
fot.write(("{COMMENT: %s}"%comment).encode())            #Comment
fot.write(("{DATE:%s}"%date).encode())                   #Date:2005-11-25;12:33:51
fot.write(("{CLOCK:%s}"%clock).encode())                 #Wavefm Clock
fot.write(("{CLOCK MARKER: %s}"%clock).encode())         #Marker Clock
fot.write(("{LEVEL OFFS:%.4f,%.4f}"%(RMS,MAX)).encode()) #RMS,Peak
                                                         #RMS : 10*log(sum(i^2+q^2)/numsamp)
                                                         #Peak: 10*log(max(i^2+q^2))
fot.write(("{SAMPLES:%d}"%samples).encode())             #NumSamples
#fot.write(("{CONTROL LENGTH:%d}"%samples).encode())     #NumSamples MkrOnly?
fot.write("{MARKER LIST 1: 0:1;20:0}".encode())          #MkrList MkrOnly
fot.write("{MARKER LIST 2: 0:0}".encode())               #MkrList MkrOnly
fot.write("{MARKER LIST 3: 0:0}".encode())               #MkrList MkrOnly
fot.write("{MARKER LIST 4: 0:0}".encode())               #MkrList MkrOnly
fot.write(("{WAVEFORM-%d: #"%(4*samples+1)).encode())    #Waveform = NumSamples * 4 + 1

#*****************************************************************
# File Data Write
#
# IQData is a 2byte little edian integer
# IQData = Round(Real * 32768)
#*****************************************************************
i=0
for IQ in IQArry:
   if (IQ[0] > 1) or (IQ[1] > 1):
      print("Error IQ > 1: %f, %f"%(IQ[0],IQ[1]))
   data = int(round(IQ[0] * 32767))
   data = struct.pack('<h',data)             #i:4byte h:2byte H:unsigned2byte
   fot.write(data)
   data = int(round(IQ[1] * 32767))
   data = struct.pack('<h',data)             #i:4byte h:2byte H:unsigned2byet
   fot.write(data)
fot.write("}".encode())
fot.close()                                  #Close Output File
