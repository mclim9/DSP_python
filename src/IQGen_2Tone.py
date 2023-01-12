# : Martin C Lim: 2017.10.04
import sys
import numpy             as np
from IQGen_Common        import Common                      # pylint: disable=E0401

class IQGen(Common):
    def __init__(self):
        super().__init__()
        self.maxAmpl    = 1                                 # clipping value
        self.OverSamp   = 30                                # Oversampling
        self.FC1        = 1e6                               # Tone1,Hz
        self.FC2        = 3e6                               # Tone2,Hz
        self.NumPeriods = 10                                # Number of Periods
        self.fBeta      = 0.2                               # Filter Beta
        self.IQpoints   = 0                                 # Display points
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

    def Gen1Tone_IQ(self):
        # ## I:Cos Q:Sin  -Frq:Nul +Frq:Pos 1.000 Normal Case
        # ## I:Sin Q:Cos  -Frq:Neg +Frq:Nul 1.500
        # ## I:Cos Q:Zer  -Frq:Pos +Frq:Pos 0.500
        # ## I:Sin Q:Zer  -Frq:Neg +Frq:Neg 0.015
        # ## I:Zer Q:Sin  -Frq:Neg +Frq:Pos 0.500
        # ## I:Zer Q:Cos  -Frq:Neg +Frq:Pos 0.015

        self.Fs = self.OverSamp * (self.FC1)                  # Sampling Frequency
        StopTime = self.NumPeriods / self.FC1                 # Waveforms
        # t = np.arange(0, StopTime, 1/self.Fs)                # create time array
        t = np.linspace(0, StopTime, num=self.OverSamp * self.NumPeriods, endpoint=False)     # Create time array
        #  self.IData = 0.7071 * np.cos(2*np.pi*self.FC1*t)
        #  self.QData = 0.7071 * np.sin(2*np.pi*self.FC1*t)
        self.IData = np.cos(2 * np.pi * self.FC1 * t)
        self.QData = np.sin(2 * np.pi * self.FC1 * t)

        # ## Clipping
        maxA = self.maxAmpl
        for i, currVal in enumerate(self.IData):
            if currVal > self.maxAmpl:
                self.IData[i] = maxA
            if currVal < -self.maxAmpl:
                self.IData[i] = -maxA
        for i, currVal in enumerate(self.QData):
            if currVal > self.maxAmpl:
                self.QData[i] = maxA
            if currVal < -self.maxAmpl:
                self.QData[i] = -maxA

        print(f"GenCW: {self.FC1/1e6:.3f}MHz tone RBW:{self.FC1 / self.NumPeriods / 1e3:.3f}kHz")
        print(f"GenCW: {self.Fs/self.FC1:.2f} Oversample")

    def Gen1Tone_Analog(self):

        self.Fs = self.OverSamp * (self.FC1)                  # Sampling Frequency
        StopTime = self.NumPeriods / self.FC1                 # Waveforms
        t = np.linspace(0, StopTime, num=self.OverSamp * self.NumPeriods, endpoint=False)     # Create time array
        self.IData = np.cos(2 * np.pi * self.FC1 * t)
        self.QData = np.arange(0, StopTime)

        # ## Clipping
        maxA = self.maxAmpl
        for i, currVal in enumerate(self.IData):
            if currVal > self.maxAmpl:
                self.IData[i] = maxA
            if currVal < -self.maxAmpl:
                self.IData[i] = -maxA

        print(f"GenCW: {self.FC1/1e6:.3f}MHz tone RBW:{self.FC1/self.NumPeriods/1e3:.3f}kHz")
        print(f"GenCW: {self.Fs/self.FC1:.2f} Oversample")

    def Gen2Tone(self):
        self.Fs = self.OverSamp * (self.FC1)                # Sampling Frequency
        StopTime = self.NumPeriods / self.FC1               # Waveforms
        dt = 1 / self.Fs                                    # seconds per sample
        t = np.arange(0, StopTime, dt)                      # create time array
        t = np.linspace(0, StopTime, num=self.OverSamp * self.NumPeriods, endpoint=False)     # Create time array
        I1_Ch = 0.7071 * np.cos(2 * np.pi * self.FC1 * t)
        Q1_Ch = 0.7071 * np.sin(2 * np.pi * self.FC1 * t)
        I2_Ch = 0.7071 * np.cos(2 * np.pi * self.FC2 * t)
        Q2_Ch = 0.7071 * np.sin(2 * np.pi * self.FC2 * t)
        self.IData = I1_Ch + I2_Ch
        self.QData = Q1_Ch + Q2_Ch

        print(f"GenCW: {self.FC1 / 1e6:.3f}MHz {self.FC2 / 1e6:.3f}MHz tones generated")
        print(f"GenCW: {self.Fs / self.FC1:.2f} {self.Fs / self.FC2:.2f} Oversample")

# #####################################################################
# ## Run if Main
# #####################################################################
if __name__ == "__main__":
    print(sys.version)
    Wvform = IQGen()                                        # Create object
    Wvform.maxAmpl    = 1                                   # clipping value
    Wvform.OverSamp   = 30                                  # Oversampling
    Wvform.FC1        = 100e6                               # Tone1,Hz
    Wvform.FC2        = 3e6                                 # Tone2,Hz
    Wvform.NumPeriods = 12                                  # Number of Periods
    # Wvform.Gen2Tone()                                     # Two tones, FC1 FC2
    Wvform.Gen1Tone_IQ()
    # Wvform.Gen1Tone_Analog()                              # One tones, FC1
    # Wvform.VSG_SCPI_Write()
    # Wvform.plot_IQ_FFT()

    for i in range(1, 5, 1):
        Wvform.FC1        = i * 100e6                       # Tone1,Hz
        Wvform.filename = f'IQGen_1Tone_{Wvform.FC1/1e6:.0f}MHz.env'
        Wvform.WvWrite("IQGen_2Tone")
        Wvform.createWv()
