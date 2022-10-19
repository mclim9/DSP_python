class CWVar:
    def __init__(self):
        self.maxAmpl = 1.0                      # clipping value
        self.OverSamp = 10                      # Oversampling
        self.FC1 = 1.5e6                        # Tone1,Hz
        self.FC2 = 2.0e6                        # Tone2,Hz
        self.NumPeriods = 60                    # Number of Periods
        self.fBeta = 10                         # Filter Beta

    def __str__(self):
        OutStr = 'maxAmpl     : %5.2f\n' % self.maxAmpl +\
                 'OverSamp    : %5.2f\n' % self.OverSamp +\
                 'FC1          : %5.2f\n' % self.FC1 +\
                 'FC2          : %5.2f\n' % self.FC2 +\
                 'NumPeriods : %5.2f\n' % self.NumPeriods +\
                 'fBeta        : %5.2f\n' % self.fBeta
        return OutStr

if __name__ == "__main__":
    Test = CWVar()
    print(Test)
