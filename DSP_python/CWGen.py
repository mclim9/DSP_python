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
      
      print("GenCW: %.3fMHz %.3fMHz tones generated"%(self.FC1/1e6,self.FC2/1e6))
      print("GenCW: %.2f %.2f Oversample"%(Fs/self.FC1,Fs/self.FC2))

      self.WvWrite(Fs,I_Ch,Q_Ch)
      self.plot_IQ_FFT(Fs, I_Ch, Q_Ch)
      try:
         self.GUI_Element.insert(0,"CWGen")
         self.GUI_Object.update()
      except:
         pass

   def Gen_FMChirpSum(self):
      ##################################################################
      ### Source:  
      ### 
      ##################################################################
      ### User Input
      ##################################################################
      #self.FC1                                       #Start Frequency
      Fs = 2.0e9;                                     #Sampling Frequency
      RampTime = 10e-6                                #Time from F1 to F2
      
      Points  = int(Fs * RampTime);                   #Num waveform points
      #I_Ch = [0.00] * Points                          #Create empty array
      #Q_Ch = [0.00] * Points                          #Create empty array
      fm1 = np.arange(-self.FC1/2,+self.FC1/2,self.FC1/(Points-1))        #freq vs time
      phase = 2.0 * np.pi / Fs * np.cumsum(fm1);      #freq vs time --> phase vs time

      I_Ch = 0.707 * np.cos(phase);                   #Gen I Data
      Q_Ch = 0.707 * np.sin(phase);                   #Gen Q Data

      print("Points" + str(Points))
      if 1:  #Up and down sweep
         fm2 = np.arange(+self.FC1/2,-self.FC1/2,self.FC1/(Points-1))        #freq vs time
         phase = 2.0 * np.pi / Fs * np.cumsum(fm2);   #freq vs time --> phase vs time
         I_Dn = 0.707 * np.cos(phase)                 #Gen I Data
         Q_Dn = 0.707 * np.sin(phase)                 #Gen Q Data
         I_Ch = np.concatenate((I_Ch,I_Dn))
         Q_Ch = np.concatenate((Q_Ch,Q_Dn))
         print(len(I_Ch))

      cmmnt = "%f to %fMHz sweep in %fsec"%(self.FC1/1e6,self.FC2/1e6,RampTime)
      print("GenFM: " + commnt)
      
      self.WvWrite(Fs,I_Ch, Q_Ch, cmmnt)

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
      
   def Gen_FM(self):
      ### Source: https://gist.github.com/fedden/d06cd490fcceab83952619311556044a
      Fs = self.OverSamp*(self.FC1);               #Sampling Frequency
      StopTime = self.NumPeriods/self.FC1;         #Waveforms
      dt = 1/Fs;                                   #seconds per sample
      time = np.arange(0,StopTime,dt);             #create time array
      #time = np.arange(NumPts) / NumPts      
      modIndx = 3

      rmp_arry = self.FuncGenTri(time.size,modIndx)
      sin_arry = np.sin(2.0 * np.pi * self.Fmod * time) 
      cos_arry = np.cos(2.0 * np.pi * self.Fmod * time) 
      mod_arry = rmp_arry
      I_Ch = np.zeros_like(mod_arry)
      Q_Ch = np.zeros_like(mod_arry)
      for i, t in enumerate(time):
          print(t)
          ### sin(2(pi)fc+(beta)sin(2(pi)fm))
          ### sin(2(pi)fc+(beta)modArry)
          I_Ch[i] = np.cos(2.0*np.pi*self.FC1*t + modIndx*mod_arry[i])
          Q_Ch[i] = np.sin(2.0*np.pi*self.FC1*t + modIndx*mod_arry[i])
      print("GenFM: FC:%.3fMHz Fmod:%.3fMHz tones generated"%(self.FC1/1e6,self.Fmod/1e6))

      self.WvWrite(Fs,I_Ch, Q_Ch)
      self.plot_IQ_FFT(Fs, I_Ch, Q_Ch, mod_arry)
      
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
#   Wvform.Gen2Tone()               #Call main
#   Wvform.Gen_FM()
   Wvform.Gen_FMChirp()
   
   execfile("CreateWv.py")
