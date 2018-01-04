from __future__ import division     #int div to float
# *****************************************************************
# Title: Simple GUI to display DSP concepts
#
# Description:
#
#
# *****************************************************************
# User Input Settings
# *****************************************************************
btnWid = 15
textWindWid = 120
maxCol = 6
btnRow = 20
ColorBG = "black"  #gray30
ColorFG = "green"
ColorCurs = "White"

# *****************************************************************
# Code Start
# *****************************************************************
#from Tkinter import *
import Tkinter
import ttk
import tkMessageBox
import tkFileDialog
END = Tkinter.END

#Code specific libraries
import random
import math
import pickle     #to save/load object
import copy       #copy object
from os.path import split
from CWGen import CWGen_Class
CWVar = CWGen_Class()

# *****************************************************************
# Functions
# *****************************************************************
def btn_Button():
   pass
   
def btn_Waveforms():
   lstWaveF.delete(0,END)
   filez = tkFileDialog.askopenfilenames()
   fileList = list(filez)
   for i in fileList:
      lstWaveF.insert(END,i)
   lstWaveF.see(END)
 
def btn_WaveCreate():
   execfile("CreateWv.py")
   
def btn_SaveCond():
   CWVar.FC1 = float(Entry1.get())
   CWVar.FC2 = float(Entry2.get())
   CWVar.NumPeriods = float(Entry3.get())
   CWVar.fBeta  = float(Entry4.get())
   dataSave(CWVar)
   
def btn_Test():
   pass
   
def btn_Clear():
   posi = lstOutpt.curselection()
   lstOutpt.delete(0,END)

def btn_PlotFFT():
   fprintf("CWGen: Run Tests")
   btn_SaveCond()
   CWVar.FC1 = float(Entry1.get())
   CWVar.FC2 = float(Entry2.get())
   CWVar.NumPeriods = float(Entry3.get())
   CWVar.fBeta  = float(Entry4.get())
   CWVar.OverSamp  = float(Entry5.get())
   #CWVar.GUI_Element = lstOutpt     #Send GUI window handle
   #CWVar.GUI_Object = GUI           #Send GUI handle
   print type(lstOutpt)
   CWVar.main()
   fprintf("CWGen Plotted")
   
def menu_Open():
   asdf = tkFileDialog.askopenfilename()
   print asdf
   
def menu_Exit():
   global GUI
   btn_SaveCond()
   GUI.quit()
   GUI.destroy()
   print("Program End")

def menu_Save():
   dataSave(RSVar)

def ArrayInput(stringIn):
   OutputList = []
   InputList = stringIn.split(",")
   for i in InputList:
      i = i.strip()
      OutputList.append(i)
   return OutputList
   
def fprintf(inStr):
   #print(inStr)
   try:
      #lstOutpt.insert(END,inStr)
      lstOutpt.insert(0,inStr)
      #lstOutpt.see(END)
      GUI.update()
   except:
      pass

def dataSave(data):
   with open("CWGen_GUI.dat","wb") as f:
      #print data
      pickle.dump(data, f)
   fprintf("DataSave: File Saved")

def dataLoad():
   try:
      with open("CWGen_GUI.dat","rb") as f:
         data = pickle.load(f)
      fprintf("DataLoad: OK")
   except:
      data = copy.copy(CWVar)
      fprintf("DataLoad: Default")
   return data
                 
# *****************************************************************
# Define GUI Widgets
# *****************************************************************
CWVar = copy.copy(dataLoad())
GUI = Tkinter.Tk()                                 #Create GUI object
GUI.title("CW to FFT View")                        #GUI Title
Lbl1 = Tkinter.Label(GUI, text="FC1")              #Create Label
Entry1 = Tkinter.Entry(GUI,bg=ColorBG, fg=ColorFG,insertbackground=ColorCurs) #Create Entry background
Entry1.insert(END, CWVar.FC1)                      #Default Value
Lbl2 = Tkinter.Label(GUI, text="FC2")              #Create Label
Entry2 = Tkinter.Entry(GUI,bg=ColorBG, fg=ColorFG,insertbackground=ColorCurs) #Entry Background
Entry2.insert(END, CWVar.FC2)                      #Default Value
Lbl3 = Tkinter.Label(GUI, text="NumPeriods")       #Create Label
Entry3 = Tkinter.Entry(GUI,bg=ColorBG, fg=ColorFG,insertbackground=ColorCurs) #Entry Background
Entry3.insert(END, CWVar.NumPeriods)               #Default Value
Lbl4 = Tkinter.Label(GUI, text="Filter Beta")      #Create Label
Entry4 = Tkinter.Entry(GUI,bg=ColorBG, fg=ColorFG,insertbackground=ColorCurs) #Entry Background
Entry4.insert(END, CWVar.fBeta)                    #Default Value
Lbl5 = Tkinter.Label(GUI, text="OverSamp=Fs/FC1")  #Create Label
Entry5 = Tkinter.Entry(GUI,bg=ColorBG, fg=ColorFG,insertbackground=ColorCurs) #Entry Background
Entry5.insert(END, CWVar.OverSamp)                 #Default Value

btnWaveF = Tkinter.Button(GUI, width=btnWid, text = "Select *.WV", command = btn_Waveforms)
btnWaveC = Tkinter.Button(GUI, width=btnWid, text = "Gen *.wv", command = btn_WaveCreate)
btnSaveC = Tkinter.Button(GUI, width=btnWid, text = "Save", command = btn_SaveCond)
btnClear = Tkinter.Button(GUI, width=btnWid, text = "Test", command = btn_Test)
btnRunIt = Tkinter.Button(GUI, width=btnWid, text = "Plot", command = btn_PlotFFT)
btnQuit  = Tkinter.Button(GUI, width=btnWid, text = "Quit", command = menu_Exit)
lstOutpt = Tkinter.Listbox(GUI, width=textWindWid,bg=ColorBG, fg=ColorFG)
srlOutpt = ttk.Scrollbar(GUI, orient=Tkinter.VERTICAL, command=lstOutpt.yview) #Create scrollbar S
lstOutpt.config(yscrollcommand=srlOutpt.set)            #Link lstOutpt change to S
lstWaveF = Tkinter.Listbox(GUI,bg=ColorBG, fg=ColorFG,width=80)
srlWaveF = ttk.Scrollbar(GUI, orient=Tkinter.VERTICAL, command=lstWaveF.yview) #Create scrollbar S
#for item in RSVar.WvArry:
#    lstWaveF.insert(END, item)

lstWaveF.config(yscrollcommand=srlWaveF.set)            #Link lstWaveF change to S
lstFrequ = Tkinter.Listbox(GUI,bg=ColorBG, fg=ColorFG)
lstPower = Tkinter.Listbox(GUI,bg=ColorBG, fg=ColorFG)

# Grid up the Widgets
Lbl1.grid(row=0,column=0,sticky=Tkinter.E,columnspan=1)
Lbl2.grid(row=1,column=0,sticky=Tkinter.E,columnspan=1)
Lbl3.grid(row=2,column=0,sticky=Tkinter.E,columnspan=1)
Lbl4.grid(row=3,column=0,sticky=Tkinter.E,columnspan=1)
Lbl5.grid(row=4,column=0,sticky=Tkinter.E,columnspan=1)
Entry1.grid(row=0,column=1,columnspan=1)
Entry2.grid(row=1,column=1,columnspan=1)
Entry3.grid(row=2,column=1,columnspan=1)
Entry4.grid(row=3,column=1,columnspan=1)
Entry5.grid(row=4,column=1,columnspan=1)

btnWaveF.grid(row=btnRow,column=0)
btnWaveC.grid(row=btnRow,column=1)
btnSaveC.grid(row=btnRow,column=2)
btnClear.grid(row=btnRow,column=3)
btnRunIt.grid(row=btnRow,column=4)
btnQuit.grid(row=btnRow,column=5)

lstWaveF.grid(row=0,column=2,columnspan=4,rowspan=5)
srlWaveF.grid(column=6,row=0,rowspan=5,sticky=(Tkinter.W,Tkinter.N,Tkinter.S))     
#lstFrequ.grid(row=0,column=4,rowspan=5)
#lstPower.grid(row=0,column=5,rowspan=5)
lstOutpt.grid(row=btnRow-1,column=0,columnspan=maxCol)
srlOutpt.grid(column=maxCol,row=btnRow-1, sticky=(Tkinter.W,Tkinter.N,Tkinter.S))     

# *****************************************************************
# Define menu
# *****************************************************************
menu = Tkinter.Menu(GUI)                        #create dropdown in GUI
GUI.config(menu=menu)

fileMenu = Tkinter.Menu(menu)                   #create dropdown in menu
fileMenu.add_command(label="Open",command=menu_Open)
fileMenu.add_command(label="Save",command=menu_Save)
fileMenu.add_separator()
fileMenu.add_command(label="Exit",command=menu_Exit)

editMenu = Tkinter.Menu(menu)                   #create dropdown in menu
editMenu.add_command(label="Edit",command=menu_Open)

menu.add_cascade(label="File",menu=fileMenu)    #add dropdown menu
menu.add_cascade(label="Edit",menu=editMenu)    #add dropdown menu

# *****************************************************************
# Start Program
# *****************************************************************
GUI.mainloop()       #Display window
