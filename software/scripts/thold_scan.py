import pyrogue.interfaces
import time

client = pyrogue.interfaces.VirtualClient('localhost',9099)

print(f"Time= {client.MultiRenaRoot.LocalTime.get()}")

# Take state steps as a script
client.MultiRenaRoot.LoadConfig("/home/ryan/work/ucsc-hn/software/scripts/defaults_scan.yml")
print("Load Done")

time.sleep(5)
client.MultiRenaRoot.Initialize()
print("Initialize Done")

Duration = 60
DataDir = "thold_single1"

#TholdValues = [180, 178, 176, 174, 172]
#ChanList = [i for i in range(25,29)]

TholdValues = [50, 44, 46, 48, 50,52,54,56,58,60,62,64]
#ChanList = [i for i in range(4,25)]
ChanList = [i for i in range(4,7)]

for chan in ChanList:

    # Update thresholds
    for thold in TholdValues:
        for b in range(7,9):
            for r in range(2):
                client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[chan].FastDac.set(thold)
                client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[chan].SlowDac.set(thold)

                # Turn off other channels
                for other in range(0,36):
                    client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[other].FastTrigEnable.setDisp('Disable')
                    client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[other].SlowTrigEnable.setDisp('Disable')

                # Turn on target channels
                client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[chan].FastTrigEnable.setDisp('Enable')
                client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[b].Rena[r].Channel[chan].SlowTrigEnable.setDisp('Enable')

        # Configure boards
        client.MultiRenaRoot.Node[0].RenaArray.ConfigBoards()
        time.sleep(2)
        client.MultiRenaRoot.Initialize()
        time.sleep(1)

        # Open data file
        client.MultiRenaRoot.DataWriter.DataFile.set(f"/home/ryan/work/ucsc-hn/software/scripts/{DataDir}/{chan:#02}_{thold:#03}.dat")
        client.MultiRenaRoot.DataWriter.Open()
        time.sleep(1)

        # Set run enable
        client.MultiRenaRoot.RunControl.runState.setDisp("Running")

        print(f"Running for {Duration} seconds Chan {chan} Thold {thold}")
        time.sleep(Duration)

        # Set run stopped
        client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")
        time.sleep(1)

        # Close data file
        client.MultiRenaRoot.DataWriter.Close()

print("Done")


# Changing dac values
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].FastDac.set(100)
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].SlowDac.set(100)

