import pyrogue.interfaces
import time

client = pyrogue.interfaces.VirtualClient('localhost',9099)

print(f"Time= {client.MultiRenaRoot.LocalTime.get()}")

# Take state steps as a script
client.MultiRenaRoot.LoadConfig("/home/radiouser/ucsc-hn/software/scripts/defaultsminimums.yml")
print("Load Done")

time.sleep(5)
client.MultiRenaRoot.Initialize()
print("Initialize Done")

# Auto name option for data file
client.MultiRenaRoot.DataWriter.AutoName()

# or you can set the name yourself
#client.MultiRenaRoot.DataWriter.DataFile.set("myfile.dat")

# Open data file
client.MultiRenaRoot.DataWriter.Open()
time.sleep(1)

# Set run enable
client.MultiRenaRoot.RunControl.runState.setDisp("Running")

print("Running for 60 seconds")

# Wait one minute
time.sleep(60)

# Set run stopped
client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")
time.sleep(2)

# Close data file
client.MultiRenaRoot.DataWriter.Close()

print("Done")

#newdacvalue = 90
#def changedacvalues():
#    client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].Fastdac.set(newdacvalue)
#    client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].Fastdac.set(newdacvalue)
#def changealldacvalues():
#    for i in range [channels that will be changed]:
#        changedacvalues():
            #Need to figure out how arguments work in functions so I can change things for a set of channels
# Changing dac values
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].FastDac.set(100)
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].SlowDac.set(100)

