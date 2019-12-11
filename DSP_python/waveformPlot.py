######################################################################
####
#### Purpose : Rohde & Schwarz DSP Filter Example
#### Author  : by Martin C Lim
#### Revision: V0.1
#### Date    : 2018.06.30
####
#######################################
#### User Input
#######################################

#######################################
#### Code Begin
#######################################
import matplotlib.pyplot as plt
import numpy as np
import sys

class CWGen_Class:
   def __init__(self):
      self.maxAmpl = 1.0;                 #clipping value
      self.OverSamp = 100;                #Oversampling
      self.FC1 = -500.0e6;                #Tone1,Hz  
      self.FC2 =500e6;                    #Tone2,Hz
      self.NumPeriods = 1000              #Number of Periods
      self.fBeta = 0;                     #Filter Beta
      self.IQlen = 0;                     #IQ Length
      self.IQpoints = 0;                  #Display points

   def Gen_FMChirp(self):
      ##################################################################
      ### Source:  https://en.wikipedia.org/wiki/Chirp
      ### sine (phi + 2Pi (F0t + (k*t*t)/2)
      ### k = (F1 - F0)/T      
      ###     F0:StartFreq 
      ###     F1:StopFreq 
      ###     T:Time to sweep from F0 to F1      
      ##################################################################
      ### User Input
      ##################################################################
      #self.FC1                                     #Start Frequency
      #self.FC2                                     #Stop Frequency
   
   def plot_IQ_FFT(self, Fs, I_Ch, Q_Ch, Plot3=[9999, 9999]):
      #######################################
      #### Calculate FFT
      #######################################
      #IQ = np.vectorize(complex)(I_Ch,Q_Ch)
      IQ = I_Ch + 1j*Q_Ch
      self.IQlen = len(I_Ch)
      
      if 0:    #Apply Filter
         fltr = np.kaiser(N, self.fBeta)
         IQ = np.multiply(IQ, fltr)
      mag = np.fft.fft(IQ)/self.IQlen
      mag = np.fft.fftshift(mag)
      #mag = mag[range(N/2)]

      #frq = (np.arange(N)*Fs)/N
      frq = np.fft.fftfreq(self.IQlen,d=1/(Fs))
      frq = np.fft.fftshift(frq)
      #frq = frq[range(N/2)]
      
      #######################################
      #### Plot Data
      #######################################
      plt.clf()
      plt.subplot(2, 1, 1)       #Time Domain
      plt.title("I:Blue Q:Yellow")
      plt.plot(I_Ch,"b",I_Ch,"b")
      plt.plot(Q_Ch,"y",Q_Ch,"y")
      if Plot3[0] != 9999:
         plt.plot(Plot3,"g",Plot3,"g")
         
      plt.subplot(2, 1, 2)       # Frequency Domain
      if self.IQpoints:
         plt.plot(frq, mag,'bo')
      plt.plot(frq, mag)
      plt.xlabel('Freq')
      plt.ylabel('magnitude')
#      plt.xlim(-3e6,3e6)
      plt.grid(True)
      plt.show()

   def plotLine(self, trace1, trace2=[1]):
      plt.plot(trace1,"b")
      if len(trace2) > 1:
         plt.plot(trace2,"y")
      plt.xlabel('time,sec')
      plt.ylabel('magnitude')
      plt.title('plot')
      plt.grid(True)
      plt.show()
#
   def plotXY(self, t, I_Ch, Q_Ch):
      #######################################
      #### Plot Data
      #######################################
      plt.plot(t, I_Ch, "b", t, Q_Ch, "y")
      #plt.plot(t, I_Ch, "bo", t, Q_Ch, "yo")
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
   #print(sys.version)
   Wvform = CWGen_Class()           #Create object
   Wvform.Gen_FMChirp()
   
