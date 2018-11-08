######################################################################
####
#### Purpose : Rohde & Schwarz Single tone generation
#### Author  :Martin C Lim
#### Revision: V0.1
#### Date    : 2017.10.04
####
#### 171004 MCL Created first version
#### 180305 MCL Add GenFM
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
      self.FC1 = 2e6;                     #Tone1,Hz  
      self.FC2 =3e6;                      #Tone2,Hz
      self.NumPeriods = 100               #Number of Periods
      self.fBeta = 0.2;                   #Filter Beta
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

   def Gen1Tone(self):
      ### I:Cos Q:Sin  -Frq:Nul +Frq:Pos 1.000 Normal Case
      ### I:Sin Q:Cos  -Frq:Neg +Frq:Nul 1.500
      ### I:Cos Q:Zer  -Frq:Pos +Frq:Pos 0.500
      ### I:Sin Q:Zer  -Frq:Neg +Frq:Neg 0.015
      ### I:Zer Q:Sin  -Frq:Neg +Frq:Pos 0.500
      ### I:Zer Q:Cos  -Frq:Neg +Frq:Pos 0.015

      Fs = self.OverSamp*(self.FC1);               #Sampling Frequency
      StopTime = self.NumPeriods/self.FC1;         #Waveforms
      #t = np.arange(0,StopTime,1/Fs);             #create time array
      t = np.linspace(0,StopTime,num=self.OverSamp*self.NumPeriods, endpoint=False);   #Create time array
      I_Ch = 0.5 * np.cos(2*np.pi*self.FC1*t);
      Q_Ch = 0.5 * np.sin(2*np.pi*self.FC1*t);
      
      print("GenCW: %.3fMHz %.3fMHz tones generated"%(self.FC1/1e6,self.FC2/1e6))
      print("GenCW: %.2f %.2f Oversample"%(Fs/self.FC1,Fs/self.FC2))

      self.WvWrite(Fs,I_Ch,Q_Ch)
      self.plot_IQ_FFT(Fs, I_Ch, Q_Ch)
      try:
         self.GUI_Element.insert(0,"CWGen")
         self.GUI_Object.update()
      except:
         pass

   def Gen2Tone(self):
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
      
      print("GenCW: %.3fMHz %.3fMHz tones generated"%(self.FC1/1e6,self.FC2/1e6))
      print("GenCW: %.2f %.2f Oversample"%(Fs/self.FC1,Fs/self.FC2))

      self.WvWrite(Fs,I_Ch,Q_Ch)
      self.plot_IQ_FFT(Fs, I_Ch, Q_Ch)
      try:
         self.GUI_Element.insert(0,"CWGen")
         self.GUI_Object.update()
      except:
         pass

   def WvWrite(self,Fs, I_Ch, Q_Ch, comment=""):
      comment = sys._getframe().f_back.f_code.co_name + ":" + comment
      print("WvWrt: %dSamples @ %.0fMHz FFTres:%.3fkHz"%(len(I_Ch),Fs/1e6, Fs/(len(I_Ch)*1e3)))
      
      fot = open("CreateWv.env", 'w')
      fot.write("#############################################\n")
      fot.write("### CWGen Waveform\n")
      fot.write("###    Waveform    : %d Samples @ %.3f MHz\n"%(len(I_Ch),Fs/1e6))
      fot.write("###    Wave Length : %.6f mSec\n"%(len(I_Ch)/Fs*1000))      
      fot.write("###    Tone1 Freq  : %.3f MHz\n"%(self.FC1/1e6))
      fot.write("###    Tone2 Freq  : %.3f MHz\n"%(self.FC2/1e6))
      fot.write("###\n")
      fot.write("#############################################\n")
      fot.write("#%s\n"%(comment))
      fot.write("%f\n"%Fs)
      for i in range(0,len(I_Ch)):
         fot.write("%f,%f\n"%(I_Ch[i],Q_Ch[i]))
      fot.close()
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
   Wvform = IQGen()           #Create object
   Wvform.Gen2Tone()                #Two tones, FC1 FC2

   try:      #Python 2.7
      execfile("CreateWv.py")
   except:   #Python 3.7
      exec(open("./CreateWv3.py").read())
