###############################################################################
#### Purpose : Rohde & Schwarz waveform generation common functions
###############################################################################
#### Code Begin
###############################################################################
import sys
import matplotlib.pyplot as plt
import numpy as np

class Common:
    def __init__(self):
        self.maxAmpl    = 1.0                               #clipping value
        self.OverSamp   = 10                                #Oversampling
        self.FC1        = 2e6                               #Tone1,Hz
        self.FC2        = 3e6                               #Tone2,Hz
        self.NumPeriods = 100                               #Number of Periods
        self.fBeta      = 0.2                               #Filter Beta
        self.IQpoints   = 0                                 #Display points

        self.Fs         = 0                                 #Sampling Rate
        self.IData      = []
        self.QData      = []
        self.IQlen      = 1

    def __str__(self):
        OutStr    = 'maxAmpl      : %5.2f\n'%self.maxAmpl +\
                    'OverSamp     : %5.2f\n'%self.OverSamp +\
                    'FC1          : %5.2f\n'%self.FC1 +\
                    'FC2          : %5.2f\n'%self.FC2 +\
                    'NumPeriods   : %5.2f\n'%self.NumPeriods +\
                    'fBeta        : %5.2f\n'%self.fBeta
        return OutStr

    def WvWrite(self, comment=""):
        comment = sys._getframe().f_back.f_code.co_name + ":" + comment     #pylint: disable=W0212
        print("WvWrt: %dSamples @ %.0fMHz FFTres:%.3fkHz"%(len(self.IData),self.Fs/1e6, self.Fs/(len(self.IData)*1e3)))
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
        #print("CWGen: %d Samples @ %.0fMHz FFT res:%f kHz"%(len(self.IData),self.Fs/1e6, self.Fs/(self.IQlen*1e3)))

    def plot_IQ_FFT(self, Plot3=[9999, 9999]):                              #pylint: disable=W0102
        #######################################
        #### Calculate FFT
        #######################################
        #IQ = np.vectorize(complex)(self.IData,self.QData)
        IQ = np.asarray(self.IData) + 1j*np.asarray(self.QData)
        self.IQlen = len(self.IData)

        # fltr = np.kaiser(len(IQ), self.fBeta)
        # IQ = np.multiply(IQ, fltr)
        mag = np.fft.fft(IQ)/self.IQlen
        mag = np.fft.fftshift(mag)                                          #mag = mag[range(N/2)]

        #frq = (np.arange(N)*self.Fs)/N
        frq = np.fft.fftfreq(self.IQlen,d=1/(self.Fs))
        frq = np.fft.fftshift(frq)                                          #frq = frq[range(N/2)]

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

        plt.subplot(2, 1, 2)                                                # Frequency Domain
        if self.IQpoints:
            plt.plot(frq, mag,'bo')
        plt.plot(frq, mag)
        plt.xlabel('Freq')
        plt.ylabel('magnitude')
        #plt.xlim(-3e6,3e6)
        plt.grid(True)
        plt.show()

    def VSG_SCPI_Write(self):
        ### :MMEM:DATA:UNPR "NVWFM://var//user//<wave.wv>",#<numSize><NumBytes><I0Q0...IxQx>
        ###     wave.wv : Name of *.wv to be created
        ###     numSize : Number of bytes in <NumBytes> string
        ###     NumBytes: Number of bytes to follow
        ###               Each I (or Q) value is two bytes
        ###               I(2 bytes) + Q(2bytes) = 4 bytes/IQ pair
        ###               NumBytes = NumIQPair * 4
        from rssd.VSG.Common    import VSG                                  #pylint: disable=C0415,E0401
        SMW = VSG().jav_Open('192.168.1.114')                               #Create SMW Object

        ### ASCII
        scpi  = ':MMEM:DATA:UNPR "NVWFM://var//user//IQGen.wv",#'           # Ascii Cmd
        iqsize= str(len(self.IData)*4)                                      # Calculate bytes of IQ data
        scpi  = scpi + str(len(iqsize)) + iqsize                            # Calculate length of iqsize string
        ### Binary
        iqdata= np.vstack((self.IData,self.QData)).reshape((-1,),order='F') # Combine I&Q Data
        bits  = np.array(iqdata*32767, dtype='>i2')                         # Convert to big-endian 2byte int
        cmd   = bytes(scpi, 'utf-8') + bits.tostring()                      # Add ASCII + Bin
        SMW.K2.write_raw(cmd)

        SMW.write('SOUR1:BB:ARB:WAV:CLOC "/var/user/IQGen.wv",%f'%self.Fs)  # Set Fs/Clk Rate
        SMW.write('BB:ARB:WAV:SEL "/var/user/IQGen.wv"')                    # Select Arb File
        print(SMW.query('SYST:ERR?'))

    def plotLine(self, trace1, trace2=[1]):                                 #pylint: disable=W0102
        plt.plot(trace1,"b")
        if len(trace2) > 1:
            plt.plot(trace2,"y")
        plt.xlabel('time,sec')
        plt.ylabel('magnitude')
        plt.title('plot')
        plt.grid(True)
        plt.show()

    def plotXY(self, t):
        """Plot IData vs QData"""
        plt.plot(t, self.IData, "b", t, self.QData, "y")
        #plt.plot(t, self.IData, "bo", t, self.QData, "yo")
        plt.xlabel('time,sec')
        plt.ylabel('magnitude')
        plt.title('plot')
        plt.grid(True)
        #plt.savefig("test.png")
        plt.show()

###############################################################################
### Run if Main
###############################################################################
if __name__ == "__main__":
    print(sys.version)
