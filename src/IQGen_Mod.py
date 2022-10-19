import sys
import numpy as np
from IQGen_Common import Common                             # pylint: disable=E0401

# #####################################################################
# ## Purpose  : Rohde & Schwarz Single tone generation
# ## Author   : Martin C Lim
# ## Revision : V0.1
# ## Date     : 2017.10.04
# ###
# ## 171004 MCL Created first version
# ## 180305 MCL Add GenFM
# ## 180410 MCL Add GenFMCW
# ## 191113 MCL add Fs,IData,Qdata into object
# #####################################################################
# ## Code Begin
# #####################################################################

class IQGen(Common):
    def __init__(self):
        super().__init__()
        self.maxAmpl    = 1.0                               # clipping value
        self.OverSamp   = 100                               # Oversampling
        self.FC1        = 5.0e6                             # Tone1,Hz
        self.FC2        = 500e6                             # Tone2,Hz
        self.NumPeriods = 10                                # Number of Periods
        self.fBeta      = 0                                 # Filter Beta
        self.IQlen      = 0                                 # IQ Length
        self.IQpoints   = 0                                 # Display points
        self.FMod       = 10e3                              # Modulation Frequency

        self.Fs         = 0                                 # Sampling Rate
        self.IData      = []
        self.QData      = []

    def __str__(self):
        OutStr = 'maxAmpl     : %5.2f\n' % self.maxAmpl +\
                 'OverSamp    : %5.2f\n' % self.OverSamp +\
                 'FC1         : %5.2f\n' % self.FC1 +\
                 'FC2         : %5.2f\n' % self.FC2 +\
                 'NumPeriods  : %5.2f\n' % self.NumPeriods +\
                 'fBeta       : %5.2f\n' % self.fBeta
        return OutStr

    def Gen_FM(self):
        # ## Source: https://gist.github.com/fedden/d06cd490fcceab83952619311556044a
        self.Fs = self.OverSamp * (self.FC1)                # Sampling Frequency
        StopTime = self.NumPeriods / self.FC1               # Waveforms
        dt = 1 / self.Fs                                    # seconds per sample
        time = np.arange(0, StopTime, dt)                   # create time array
        modIndx = 3

        # rmp_arry = self.FuncGenTri(time.size,modIndx)
        sin_arry = np.sin(2.0 * np.pi * self.FMod * time)
        # cos_arry = np.cos(2.0 * np.pi * self.FMod * time)
        mod_arry = sin_arry
        self.IData = np.zeros_like(mod_arry)
        self.QData = np.zeros_like(mod_arry)
        for i, t in enumerate(time):
            # ## sin(2(pi)fc+(beta)sin(2(pi)fm))
            # ## sin(2(pi)fc+(beta)modArry)
            self.IData[i] = np.cos(2.0 * np.pi * self.FC1 * t + modIndx * mod_arry[i])
            self.QData[i] = np.sin(2.0 * np.pi * self.FC1 * t + modIndx * mod_arry[i])
        print("GenFM: FC:%.3fMHz FMod:%.3fMHz tones generated" % (self.FC1 / 1e6, self.FMod / 1e6))

        self.WvWrite()
        # self.plot_IQ_FFT(mod_arry)

    def Gen_FMChirp(self):
        # #####################################################################
        # ## Source:  https://en.wikipedia.org/wiki/Chirp
        # ## sine (phi + 2Pi (F0t + (k * t * t)/2)
        # ## k = (F1 - F0)/T
        # ##      F0:StartFreq
        # ##      F1:StopFreq
        # ##      T:Time to sweep from F0 to F1
        # #####################################################################
        # ## User Input
        # #####################################################################
        self.Fs = 2.0e9                                     # Sampling Frequency
        RampTime = 100e-6

        # ## Code Start
        time = np.arange(0, RampTime, 1 / self.Fs)          # Create time array
        self.IData  = [0.00] * time.size                    # Create empty array
        self.QData  = [0.00] * time.size                    # Create empty array
        I_Dn        = [0.00] * time.size                    # Create empty array
        Q_Dn        = [0.00] * time.size                    # Create empty array
        K = ((self.FC2 - self.FC1) / RampTime)              # Define FM sweep rate

        for i, t in enumerate(time):
            self.IData[i] = np.cos(2.0 * np.pi * (self.FC1 * t + K * t * t / 2))
            self.QData[i] = np.sin(2.0 * np.pi * (self.FC1 * t + K * t * t / 2))
            I_Dn[i]       = np.cos(2.0 * np.pi * (self.FC2 * t - K * t * t / 2))
            Q_Dn[i]       = np.sin(2.0 * np.pi * (self.FC2 * t - K * t * t / 2))

        self.IData.extend(I_Dn)                             # Sweep I Down
        self.QData.extend(Q_Dn)                             # Sweep Q Down
        # self.IData = self.IData[::-1]                     # Reverse I
        # self.QData = self.QData[::-1]                     # Reverse Q

        commnt = "%.3f to %.3fMHz sweep in %.3fmsec" % (self.FC1 / 1e6, self.FC2 / 1e6, RampTime * 1e3)
        print("GenFM: %fsec ramp at %.0f MHz/Sec" % (RampTime, K / 1e6))
        print("GenFM: " + commnt)

        self.WvWrite(commnt)

    def Gen_FMChirpSum(self):
        ##################################################################
        # ## Source:  ???
        ##################################################################
        # ## User Input
        ##################################################################
        # self.FC1                                                  # Start Frequency
        Fs = 2.0e9                                                  # Sampling Frequency
        RampTime = 1000e-6                                          # Time from F1 to F2
        Points  = int(Fs * RampTime)                                # Num waveform points
        PhStep  = self.FC1 / (Points - 1)
        # self.IData = [0.00] * Points                              # Create empty array
        # self.QData = [0.00] * Points                              # Create empty array
        fm1 = np.arange(-self.FC1 / 2, +self.FC1 / 2, PhStep)       # freq vs time
        phase = 2.0 * np.pi / Fs * np.cumsum(fm1)                   # freq vs time --> phase vs time
        self.IData = 0.707 * np.cos(phase)                          # Gen I Data
        self.QData = 0.707 * np.sin(phase)                          # Gen Q Data

        print("Points" + str(Points))
        # if 1:                                                     # Up and down sweep
        #     fm2 = np.arange(+self.FC1/2,-self.FC1/2,PhStep)       # freq vs time
        #     phase = 2.0 * np.pi / Fs * np.cumsum(fm2)             # freq vs time --> phase vs time
        #     I_Dn = 0.707 * np.cos(phase)                          # Gen I Data
        #     Q_Dn = 0.707 * np.sin(phase)                          # Gen Q Data
        #     self.IData = np.concatenate((self.IData,I_Dn))
        #     self.QData = np.concatenate((self.QData,Q_Dn))
        #     print(len(self.IData))

        cmmnt = f"{self.FC1/1e6} to {self.FC2/1e6}MHz sweep in {RampTime}sec"
        print("GenFM: " + cmmnt)
        self.WvWrite(cmmnt)

    def Gen_PhaseMod(self):
        angle = 87
        numpt = 100
        self.Fs = self.OverSamp * (self.FC1)                          # Sampling Frequency
        mod = np.concatenate([np.ones(numpt) * angle, np.zeros(numpt)])
        self.IData = 0.5 * np.cos(mod * np.pi / 180)
        self.QData = 0.5 * np.sin(mod * np.pi / 180)
        print(self.IData)

        print("GenCW: %.3fMHz %.3fMHz tones generated" % (self.FC1 / 1e6, self.FC2 / 1e6))
        print("GenCW: %.2f %.2f Oversample" % (self.Fs / self.FC1, self.Fs / self.FC2))

        self.WvWrite()
        # self.plot_IQ_FFT(Fs, self.IData, self.QData)

        self.GUI_Element.insert(0, "CWGen")
        self.GUI_Object.update()


######################################################################
# ## Run if Main
######################################################################
if __name__ == "__main__":
    print(sys.version)
    Wvform = IQGen()                                        # Create object
    # Wvform.Gen_FM()                                       #
    # Wvform.Gen_PhaseMod()                                 # FM Chirp
    Wvform.Gen_FMChirp()                                    # Verifiecd
    Wvform.plot_IQ_FFT()

    # try:        #Python 2.7
    #     execfile("CreateWv.py")
    # except:    #Python 3.7
    #     exec(open("./CreateWv3.py").read())
