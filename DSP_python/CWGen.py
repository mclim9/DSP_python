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
#### 171004 MCL Created first version
####
#######################################
#### User Input
#######################################

#######################################
#### Code Begin
#######################################
import matplotlib.pyplot as plt
import numpy as np

class CWGen_Class:
   def __init__(self):
      self.maxAmpl = 1.0;                 #clipping value
      self.OverSamp = 100;                 #Oversampling
      self.FC1 = 10.0e6;                  #Tone1,Hz
      self.FC2 = 15.0e6;                   #Tone2,Hz
      self.NumPeriods = 60                #Number of Periods
      self.fBeta = 0;                     #Filter Beta
      self.IQlen = 0;                     #IQ Length
      self.IQpoints = 0;                  #Display points
   def __str__(self):
      OutStr = 'maxAmpl    : %5.2f\n'%self.maxAmpl +\
               'OverSamp   : %5.2f\n'%self.OverSamp +\
               'FC1        : %5.2f\n'%self.FC1 +\
               'FC2        : %5.2f\n'%self.FC2 +\
               'NumPeriods : %5.2f\n'%self.NumPeriods +\
               'fBeta      : %5.2f\n'%self.fBeta 
      return OutStr

   def Gen2Tone(self):
      ### I:Cos Q:Sin  -Frq:Nul +Frq:Pos 1.000 Normal Case
      ### I:Sin Q:Cos  -Frq:Neg +Frq:Nul 1.500
      ### I:Cos Q:Zer  -Frq:Pos +Frq:Pos 0.500
      ### I:Sin Q:Zer  -Frq:Neg +Frq:Neg 0.015
      ### I:Zer Q:Sin  -Frq:Neg +Frq:Pos 0.500
      ### I:Zer Q:Cos  -Frq:Neg +Frq:Pos 0.015

      Fs = self.OverSamp*(self.FC1);               #Sampling Frequency
      StopTime = self.NumPeriods/self.FC1;         #Waveforms
      dt = 1/Fs;                                   #seconds per sample
      t = np.arange(0,StopTime,dt);                #create time array
      t = np.linspace(0,StopTime,num=self.OverSamp*self.NumPeriods, endpoint=False);   #Create time array
      I1_Ch = 0.5 * np.cos(2*np.pi*self.FC1*t);
      Q1_Ch = 0.5 * np.sin(2*np.pi*self.FC1*t);
      I2_Ch = 0.5 * np.cos(2*np.pi*self.FC2*t);
      Q2_Ch = 0.5 * np.sin(2*np.pi*self.FC2*t);
      I_Ch = I1_Ch + I2_Ch
      Q_Ch = Q1_Ch + Q2_Ch
      self.IQlen = len(t)
      
      self.WvWrite(Fs,I_Ch,Q_Ch)
      print("CWGen: %d Samples @ %.0fMHz FFT res:%f kHz"%(len(I_Ch),Fs/1e6, Fs/(self.IQlen*1e3)))
      print("CWGen: %.3fMHz %.3fMHz tones generated"%(self.FC1/1e6,self.FC2/1e6))
      print("CWGen: %.2f %.2f Oversample"%(Fs/self.FC1,Fs/self.FC2))
      try:
         self.GUI_Element.insert(0,"CWGen")
         self.GUI_Object.update()
      except:
         pass
      self.FFT_IQ(Fs, I_Ch, Q_Ch)

   def Gen_FM(self):
      ### Source:   https://gist.github.com/fedden/d06cd490fcceab83952619311556044a
      Fs = self.OverSamp*(self.FC1);               #Sampling Frequency
      modulator_freq = self.FC2
      carrier_freq = self.FC1
      modulation_index = 1.0

      time = np.arange(44100.0) / 44100.0
      modulator = np.sin(2.0 * np.pi * modulator_freq * time) * modulation_index
      carrier = np.sin(2.0 * np.pi * carrier_freq * time)
      I_product = np.zeros_like(modulator)
      Q_product = np.zeros_like(modulator)

      for i, t in enumerate(time):
          I_product[i] = np.cos(2. * np.pi * (carrier_freq * t + modulator[i]))
          Q_product[i] = np.sin(2. * np.pi * (carrier_freq * t + modulator[i]))
          
      self.WvWrite(Fs,I_product,Q_product)
   
   def WvWrite(self,Fs, I_Ch, Q_Ch):
      fot = open("CreateWv.env", 'w')
      fot.write("#################################\n")
      fot.write("### CWGen Waveform\n")
      fot.write("###    Oversampling: %d\n"%self.OverSamp)
      fot.write("###    Tone1 Freq  : %.3f\n"%self.FC1)
      fot.write("###    Tone2 Freq  : %.3f\n"%self.FC2)
      fot.write("###    Cycles      : %d\n"%self.NumPeriods)
      fot.write("###\n")
      fot.write("#CWGen.py:%dx Oversampled %.0fHz & %.0fHz CW\n"%(self.OverSamp,self.FC1,self.FC2))
      fot.write("%f\n"%Fs)
      for i in range(0,len(I_Ch)):
         fot.write("%f,%f\n"%(I_Ch[i],Q_Ch[i]))
      fot.close()
      #print("CWGen: %d Samples @ %.0fMHz FFT res:%f kHz"%(len(I_Ch),Fs/1e6, Fs/(self.IQlen*1e3)))

   
   def FFT_IQ(self, Fs, I_Ch, Q_Ch):
      #######################################
      #### Calculate FFT
      #######################################
      #IQ = np.vectorize(complex)(I_Ch,Q_Ch)
      IQ = I_Ch + 1j*Q_Ch
      
      #fltr = np.kaiser(N, self.fBeta)
      #IQ = np.multiply(IQ, fltr)
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
      
      plt.subplot(2, 1, 2)       # Frequency Domain
      if self.IQpoints:
         plt.plot(frq, mag,'bo')
      plt.plot(frq, mag)
      plt.xlabel('Freq')
      plt.ylabel('magnitude')
#      plt.xlim(-3e6,3e6)
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
   asdf = CWGen_Class()    #Create object
   asdf.Gen2Tone()             #Call main
   #asdf.Gen_FM()
