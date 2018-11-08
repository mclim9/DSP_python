######################################################################
####
#### Purpose : Rohde & Schwarz Single tone generation
#### Author  :Martin C Lim
#### Revision: V0.1
#### Date    : 2017.10.04
####
#### 180410 MCL Add GenFMCW
#######################################
#### User Input
#######################################

#######################################
#### Code Begin
#######################################
import matplotlib.pyplot as plt
import numpy as np
import sys

class IQGen:
   def __init__(self):
      self.maxAmpl = 1.0;                 #clipping value
      self.OverSamp = 100;                #Oversampling
      self.FC1 = 5.0e6;                   #StartFreq,Hz  
      self.FC2 =500e6;                    #StopFreq,Hz
      self.fBeta = 0;                     #Filter Beta
      self.IQlen = 0;                     #IQ Length
      self.IQpoints = 0;                  #Display points

   def __str__(self):
      OutStr = 'maxAmpl    : %5.2f\n'%self.maxAmpl +\
               'OverSamp   : %5.2f\n'%self.OverSamp +\
               'FC1        : %5.2f\n'%self.FC1 +\
               'FC2        : %5.2f\n'%self.FC2 +\
               'fBeta      : %5.2f\n'%self.fBeta 
      return OutStr
      
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
      #self.FC1                                    #Start Frequency
      #self.FC2                                    #Stop Frequency
      Fs = 2.0e9;                                  #Sampling Frequency
      RampTime = 10e-6

      ### Code Start
      time = np.arange(0,RampTime,1/Fs);           #Create time array
      I_Ch = [0.00] * time.size                    #Create empty array
      Q_Ch = [0.00] * time.size                    #Create empty array
      I_Dn = [0.00] * time.size                    #Create empty array
      Q_Dn = [0.00] * time.size                    #Create empty array
      K = ((self.FC2-self.FC1)/RampTime)           #Define FM sweep rate
      
      for i, t in enumerate(time):
          I_Ch[i] = np.cos(2.0*np.pi*(self.FC1*t + K*t*t/2))
          Q_Ch[i] = np.sin(2.0*np.pi*(self.FC1*t + K*t*t/2))
          I_Dn[i] = np.cos(2.0*np.pi*(self.FC2*t - K*t*t/2))
          Q_Dn[i] = np.sin(2.0*np.pi*(self.FC2*t - K*t*t/2))
            
      if 1:  #Up and down sweep
         I_Ch.extend(I_Dn)
         Q_Ch.extend(Q_Dn) 

      if 0:  #Reverse Array
         I_Ch = I_Ch[::-1]
         Q_Ch = Q_Ch[::-1]
         
      commnt = "%.3f to %.3fMHz sweep in %.3fmsec"%(self.FC1/1e6,self.FC2/1e6,RampTime*1e3)
      print("GenFM: %fsec ramp at %.0f MHz/Sec"%(RampTime,K/1e6))
      print("GenFM: " + commnt)
      
      self.WvWrite(Fs,I_Ch, Q_Ch, commnt)
      #self.plot_IQ_FFT(Fs, I_Ch, Q_Ch)

   def WvWrite(self,Fs, I_Ch, Q_Ch, comment=""):
      comment = sys._getframe().f_back.f_code.co_name + ":" + comment
      print("WvWrt: %dSamples @ %.0fMHz FFTres:%.3fkHz"%(len(I_Ch),Fs/1e6, Fs/(len(I_Ch)*1e3)))
      
      fot = open("CreateWv.env", 'w')
      fot.write("#############################################\n")
      fot.write("###  Waveform\n")
      fot.write("###    Waveform    : %d Samples @ %.3f MHz\n"%(len(I_Ch),Fs/1e6))
      fot.write("###    Wave Length : %.6f mSec\n"%(len(I_Ch)/Fs*1000))      
      fot.write("###    Start Freq  : %.3f MHz\n"%(self.FC1/1e6))
      fot.write("###    Stop  Freq  : %.3f MHz\n"%(self.FC2/1e6))
      fot.write("###\n")
      fot.write("#############################################\n")
      fot.write("#%s\n"%(comment))
      fot.write("%f\n"%Fs)
      for i in range(0,len(I_Ch)):
         fot.write("%f,%f\n"%(I_Ch[i],Q_Ch[i]))
      fot.close()
      print(Q_Ch)
      #print("CWGen: %d Samples @ %.0fMHz FFT res:%f kHz"%(len(I_Ch),Fs/1e6, Fs/(self.IQlen*1e3)))
   
   def plot_IQ_FFT(self, Fs, I_Ch, Q_Ch, Plot3=[9999, 9999]):
      #######################################
      #### Calculate FFT
      #######################################
      #IQ = np.vectorize(complex)(I_Ch,Q_Ch)
      IQ = I_Ch + 1j*Q_Ch
      self.IQlen = len(I_Ch)
      
      if 0:    #Apply Filter
         fltr = np.kaiser(len(IQ), self.fBeta)
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
      #plt.xlim(-3e6,3e6)
      plt.grid(True)
      plt.show()


#####################################################################
### Run if Main
#####################################################################
if __name__ == "__main__":
   print(sys.version)
   Wvform = IQGen()                 #Create object
   Wvform.Gen_FMChirp()             #FM Chirp FC1-->FC2
   
   try:      #Python 2.7
      execfile("CreateWv.py")
   except:   #Python 3.7
      exec(open("./CreateWv3.py").read())
