######################################################################
#### Rohde & Schwarz Single tone generation
######################################################################
####
#### This program will test various baseband analysis input types.  
####
#### Modified by Martin C Lim
#### Revision: V0.1
#### Date    : 2017.10.04
####
#### 171204 MCL Created first version
####
#######################################
#### User Input
#######################################
maxAmpl = 1.0;                #clipping value
OverSamp = 10;                #Oversampling
FC1 = 1.0;                  #Tone1,Hz
FC2 = 2.5e6;                  #Tone2,Hz
NumPeriods = 60
fBeta = 0;                   #Filter Beta
#######################################
#### Code Begin
#######################################
import matplotlib.pyplot as plt
import numpy as np

def Gen1Tone():
   Fs = OverSamp*FC1;               #Sampling Frequency
   StopTime = NumPeriods/FC1;       #Waveforms
   dt = 1/Fs;                       #seconds per sample
   t = np.arange(0,StopTime-dt,dt); #create time array
   I_Ch = np.cos(2*np.pi*FC1*t);
   Q_Ch = np.sin(2*np.pi*FC1*t);
   #Q_Ch = np.zeros(len(t))

   #Q_Ch(Q_Ch>maxVal) = maxVal;      #clip Q_Ch maxVal
   #Q_Ch(Q_Ch<-maxVal) = -maxVal;    #clip Q_Ch minVal
   #I_Ch(I_Ch>maxVal) = maxVal;      #clip Q_Ch maxVal
   #I_Ch(I_Ch<-maxVal) = -maxVal;    #clip Q_Ch minVal

   fot = open("CreateWv.env", 'w')
   fot.write("#################################\n")
   fot.write("### CWGen Waveform\n")
   fot.write("###    Oversampling: %d\n"%OverSamp)
   fot.write("###    Tone Freq   : %.3f\n"%FC1)
   fot.write("###    Cycles      : %d\n"%NumPeriods)
   fot.write("###\n")
   fot.write("#CWGen.py:%dx Oversampled %.0fHz CW\n"%(OverSamp,FC1))
   fot.write("%f\n"%Fs)
   for i in range(0,len(I_Ch)):
      fot.write("%f,%f\n"%(I_Ch[i],Q_Ch[i]))
   fot.close()
   print("CWGen: %.0fHz tone generated"%FC1)
   
   #######################################
   #### Frequency Domain
   #######################################
   FFT_IQ(Fs, I_Ch, Q_Ch)

def Gen2Tone():
   Fs = OverSamp*(FC2*FC1)/1e6;     #Sampling Frequency
   StopTime = NumPeriods/FC1;       #Waveforms
   dt = 1/Fs;                       #seconds per sample
   t = np.arange(0,StopTime,dt); #create time array
   I1_Ch = 0.5 * np.cos(2*np.pi*FC1*t);
   Q1_Ch = 0.5 * np.sin(2*np.pi*FC1*t);
   I2_Ch = 0.5 * np.cos(2*np.pi*FC2*t);
   Q2_Ch = 0.5 * np.sin(2*np.pi*FC2*t);
   I_Ch = I1_Ch + I2_Ch
   Q_Ch = Q1_Ch + Q2_Ch

   fot = open("CreateWv.env", 'w')
   fot.write("#################################\n")
   fot.write("### CWGen Waveform\n")
   fot.write("###    Oversampling: %d\n"%OverSamp)
   fot.write("###    Tone1 Freq  : %.3f\n"%FC1)
   fot.write("###    Tone2 Freq  : %.3f\n"%FC2)
   fot.write("###    Cycles      : %d\n"%NumPeriods)
   fot.write("###\n")
   fot.write("#CWGen.py:%dx Oversampled %.0fHz & %.0fHz CW\n"%(OverSamp,FC1,FC2))
   fot.write("%f\n"%Fs)
   for i in range(0,len(I_Ch)):
      fot.write("%f,%f\n"%(I_Ch[i],Q_Ch[i]))
   fot.close()
   print("Gen2Tone: Sampling Rate %.0fMHz"%(Fs/1e6))
   print("Gen2Tone: %.0fHz %.0fHz tones generated"%(FC1,FC2))
   print("Gen2Tone: %.2f %.2f oversample"%(Fs/FC1,Fs/FC2))
   FFT_IQ(Fs, I_Ch, Q_Ch)

def FFT_IQ(Fs, I_Ch, Q_Ch):
   #######################################
   #### Calculate FFT
   #######################################
   #IQ = np.vectorize(complex)(I_Ch,Q_Ch)
   IQ = I_Ch + 1j*Q_Ch
   
   N = len(IQ)
   fltr = np.kaiser(N, fBeta)
   IQ = np.multiply(IQ, fltr)
   mag = np.fft.fft(IQ)/N
   mag = np.fft.fftshift(mag)
   #mag = mag[range(N/2)]

   #frq = (np.arange(N)*Fs)/N
   print("FFT resolution: %.2f"%(Fs/N/1e6))
   frq = np.fft.fftfreq(N,d=1/(Fs))
   frq = np.fft.fftshift(frq)
   #frq = frq[range(N/2)]
   
   #######################################
   #### Plot Data
   #######################################
   plt.subplot(2, 1, 1)
#   plt.plot(I_Ch)
#   plt.plot(Q_Ch)
   plt.plot(IQ,"y")
   
   plt.subplot(2, 1, 2)
   plt.plot(frq, mag)
   plt.xlabel('Freq')
   plt.ylabel('magnitude')
   plt.xlim(-3e6,3e6)
   plt.grid(True)
   plt.show()

def plotLine(arry):
   plt.plot(arry)
   plt.xlabel('time,sec')
   plt.ylabel('magnitude')
   plt.title('plot')
   plt.grid(True)
   plt.show()

def plotXY(t, I_Ch, Q_Ch):
   #######################################
   #### Plot Data
   #######################################
   plt.plot(t, I_Ch, t, Q_Ch)
   plt.xlabel('time,sec')
   plt.ylabel('magnitude')
   plt.title('plot')
   plt.grid(True)
   #plt.savefig("test.png")
   plt.show()

#####################################################################
### Run if Main
#####################################################################
if __name__ == "__main__":
   Gen2Tone()
   #plotData(t, I_Ch, Q_Ch)
