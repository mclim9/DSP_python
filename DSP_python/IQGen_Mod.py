######################################################################
####
#### Purpose  : Rohde & Schwarz Single tone generation
#### Author   : Martin C Lim
#### Revision : V0.1
#### Date     : 2017.10.04
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
        self.maxAmpl    = 1.0                               #clipping value
        self.OverSamp   = 100                               #Oversampling
        self.FC1        = 5.0e6                             #Tone1,Hz
        self.FC2        = 500e6                             #Tone2,Hz
        self.NumPeriods = 10                                #Number of Periods
        self.fBeta      = 0                                 #Filter Beta
        self.IQlen      = 0                                 #IQ Length
        self.IQpoints   = 0                                 #Display points
        self.FMod       = 10e3                              # Modulation Frequency

        self.Fs         = 0                                 #Sampling Rate
        self.IData      = []
        self.QData      = []

    def __str__(self):
        OutStr = 'maxAmpl     : %5.2f\n'%self.maxAmpl +\
                'OverSamp    : %5.2f\n'%self.OverSamp +\
                'FC1          : %5.2f\n'%self.FC1 +\
                'FC2          : %5.2f\n'%self.FC2 +\
                'NumPeriods : %5.2f\n'%self.NumPeriods +\
                'fBeta        : %5.2f\n'%self.fBeta 
        return OutStr

    def Gen_FM(self):
        ### Source: https://gist.github.com/fedden/d06cd490fcceab83952619311556044a
        self.Fs = self.OverSamp*(self.FC1)                  #Sampling Frequency
        StopTime = self.NumPeriods/self.FC1                 #Waveforms
        dt = 1/self.Fs                                      #seconds per sample
        time = np.arange(0,StopTime,dt)                     #create time array
        modIndx = 3

        # rmp_arry = self.FuncGenTri(time.size,modIndx)
        sin_arry = np.sin(2.0 * np.pi * self.FMod * time) 
        # cos_arry = np.cos(2.0 * np.pi * self.FMod * time) 
        mod_arry = sin_arry
        self.IData = np.zeros_like(mod_arry)
        self.QData = np.zeros_like(mod_arry)
        for i, t in enumerate(time):
             print(t)
             ### sin(2(pi)fc+(beta)sin(2(pi)fm))
             ### sin(2(pi)fc+(beta)modArry)
             self.IData[i] = np.cos(2.0*np.pi*self.FC1*t + modIndx*mod_arry[i])
             self.QData[i] = np.sin(2.0*np.pi*self.FC1*t + modIndx*mod_arry[i])
        print("GenFM: FC:%.3fMHz FMod:%.3fMHz tones generated"%(self.FC1/1e6,self.FMod/1e6))

        self.WvWrite()
        # self.plot_IQ_FFT(mod_arry)

    def Gen_FMChirp(self):
        ##################################################################
        ### Source:  https://en.wikipedia.org/wiki/Chirp
        ### sine (phi + 2Pi (F0t + (k*t*t)/2)
        ### k = (F1 - F0)/T
        ###      F0:StartFreq
        ###      F1:StopFreq
        ###      T:Time to sweep from F0 to F1
        ##################################################################
        ### User Input
        ##################################################################
        #self.FC1                                           #Start Frequency
        #self.FC2                                           #Stop Frequency
        self.Fs = 2.0e9                                     #Sampling Frequency
        RampTime = 100e-6

        ### Code Start
        time = np.arange(0,RampTime,1/self.Fs)              #Create time array
        self.IData  = [0.00] * time.size                    #Create empty array
        self.QData  = [0.00] * time.size                    #Create empty array
        I_Dn        = [0.00] * time.size                    #Create empty array
        Q_Dn        = [0.00] * time.size                    #Create empty array
        K = ((self.FC2-self.FC1)/RampTime)                  #Define FM sweep rate

        for i, t in enumerate(time):
             self.IData[i] = np.cos(2.0*np.pi*(self.FC1*t + K*t*t/2))
             self.QData[i] = np.sin(2.0*np.pi*(self.FC1*t + K*t*t/2))
             I_Dn[i]       = np.cos(2.0*np.pi*(self.FC2*t - K*t*t/2))
             Q_Dn[i]       = np.sin(2.0*np.pi*(self.FC2*t - K*t*t/2))

        if 1:  #Up and down sweep
            self.IData.extend(I_Dn)
            self.QData.extend(Q_Dn) 

        if 0:  #Reverse Array
            self.IData = self.IData[::-1]
            self.QData = self.QData[::-1]
            
        commnt = "%.3f to %.3fMHz sweep in %.3fmsec"%(self.FC1/1e6,self.FC2/1e6,RampTime*1e3)
        print("GenFM: %fsec ramp at %.0f MHz/Sec"%(RampTime,K/1e6))
        print("GenFM: " + commnt)
        
        self.WvWrite(commnt)

    def Gen_FMChirpSum(self):
        ##################################################################
        ### Source:  ???
        ### 
        ##################################################################
        ### User Input
        ##################################################################
        #self.FC1                                           #Start Frequency
        Fs = 2.0e9                                          #Sampling Frequency
        RampTime = 10e-6                                    #Time from F1 to F2
        
        Points  = int(Fs * RampTime)                        #Num waveform points
        #self.IData = [0.00] * Points                             #Create empty array
        #self.QData = [0.00] * Points                             #Create empty array
        fm1 = np.arange(-self.FC1/2,+self.FC1/2,self.FC1/(Points-1))          #freq vs time
        phase = 2.0 * np.pi / Fs * np.cumsum(fm1)           #freq vs time --> phase vs time

        self.IData = 0.707 * np.cos(phase)                        #Gen I Data
        self.QData = 0.707 * np.sin(phase)                        #Gen Q Data

        print("Points" + str(Points))
        if 1:  #Up and down sweep
            fm2 = np.arange(+self.FC1/2,-self.FC1/2,self.FC1/(Points-1))          #freq vs time
            phase = 2.0 * np.pi / Fs * np.cumsum(fm2)       #freq vs time --> phase vs time
            I_Dn = 0.707 * np.cos(phase)                    #Gen I Data
            Q_Dn = 0.707 * np.sin(phase)                    #Gen Q Data
            self.IData = np.concatenate((self.IData,I_Dn))
            self.QData = np.concatenate((self.QData,Q_Dn))
            print(len(self.IData))

        cmmnt = "%f to %fMHz sweep in %fsec"%(self.FC1/1e6,self.FC2/1e6,RampTime)
        print("GenFM: " + cmmnt)
        
        self.WvWrite(Fs,self.IData, self.QData, cmmnt)

    def Gen_PhaseMod(self):
        angle = 87 
        numpt = 100
        self.Fs = self.OverSamp*(self.FC1)                  #Sampling Frequency
        mod = np.concatenate([np.ones(numpt)*angle,np.zeros(numpt)])
        self.IData = 0.5 * np.cos(mod * np.pi / 180)
        self.QData = 0.5 * np.sin(mod * np.pi / 180)
        print(self.IData)

        print("GenCW: %.3fMHz %.3fMHz tones generated"%(self.FC1/1e6,self.FC2/1e6))
        print("GenCW: %.2f %.2f Oversample"%(self.Fs/self.FC1,self.Fs/self.FC2))

        self.WvWrite()
        # self.plot_IQ_FFT(Fs, self.IData, self.QData)
        try:
            self.GUI_Element.insert(0,"CWGen")
            self.GUI_Object.update()
        except:
            pass

    def WvWrite(self, comment=""):
        comment = sys._getframe().f_back.f_code.co_name + ":" + comment
        print("WvWrt: %dSamples @ %.0fMHz FFTres:%.3fkHz"%(len(self.IData),self.Fs/1e6,self.Fs/(len(self.IData)*1e3)))
        
        fot = open("CreateWv.env", 'w')
        fot.write("#############################################\n")
        fot.write("### CWGen Waveform\n")
        fot.write("###     Waveform     : %d Samples @ %.3f MHz\n"%(len(self.IData),self.Fs/1e6))
        fot.write("###     Wave Length : %.6f mSec\n"%(len(self.IData)/self.Fs*1000))        
        fot.write("###     Tone1 Freq  : %.3f MHz\n"%(self.FC1/1e6))
        fot.write("###     Tone2 Freq  : %.3f MHz\n"%(self.FC2/1e6))
        fot.write("###\n")
        fot.write("#############################################\n")
        fot.write("#%s\n"%(comment))
        fot.write("%f\n"%self.Fs)
        for i in range(0,len(self.IData)):
            fot.write("%f,%f\n"%(self.IData[i],self.QData[i]))
        fot.close()
        #print("CWGen: %d Samples @ %.0fMHz FFT res:%f kHz"%(len(self.IData),Fs/1e6, Fs/(self.IQlen*1e3)))
    
    def plot_IQ_FFT(self, Plot3=[9999, 9999]):
        #######################################
        #### Calculate FFT
        #######################################
        IQ = np.asarray(self.IData) + 1j*np.asarray(self.QData)
        self.IQlen = len(self.IData)
        
        if 0:     #Apply Filter
            fltr = np.kaiser(N, self.fBeta)
            IQ = np.multiply(IQ, fltr)
        mag = np.fft.fft(IQ)/self.IQlen
        mag = np.fft.fftshift(mag)
        #mag = mag[range(N/2)]

        frq = np.fft.fftfreq(self.IQlen,d=1/(self.Fs))
        frq = np.fft.fftshift(frq)

        #######################################
        #### Plot Data
        #######################################
        plt.clf()
        plt.subplot(2, 1, 1)         #Time Domain
        plt.title("I:Blue Q:Yellow")
        plt.plot(self.IData,"b",self.IData,"b")
        plt.plot(self.QData,"y",self.QData,"y")
        if Plot3[0] != 9999:
            plt.plot(Plot3,"g",Plot3,"g")
            
        plt.subplot(2, 1, 2)         # Frequency Domain
        if self.IQpoints:
            plt.plot(frq, mag,'bo')
        plt.plot(frq, mag)
        plt.xlabel('Freq')
        plt.ylabel('magnitude')
        #plt.xlim(-3e6,3e6)
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
    def plotXY(self, t):
        #######################################
        #### Plot Data
        #######################################
        plt.plot(t, self.IData, "b", t, self.QData, "y")
        #plt.plot(t, self.IData, "bo", t, self.QData, "yo")
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
    print(sys.version)
    Wvform = IQGen()                                        #Create object
    Wvform.Gen_FM()                                        #One tone: FC1
    # Wvform.Gen_PhaseMod()
    # Wvform.Gen_FMChirp()
    Wvform.plot_IQ_FFT()

    try:        #Python 2.7
        execfile("CreateWv.py")
    except:    #Python 3.7
        exec(open("./CreateWv3.py").read())
