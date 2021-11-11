import pyrogue.interfaces
import time

client = pyrogue.interfaces.VirtualClient('localhost',9099)

print(f"Time= {client.MultiRenaRoot.LocalTime.get()}")

# Cleanup
client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")
client.MultiRenaRoot.DataWriter.Close()

# Take state steps as a script
client.MultiRenaRoot.LoadConfig("/home/ril/slac_testing/ucsc-hn/software/scripts")
print("Load Done")

time.sleep(5)
client.MultiRenaRoot.Initialize()
print("Initialize Done")

Duration = 300
DataDir = "thold_single2"

Scans = [ { 'channels'   : [i for i in range(4,25)],
            'thresholds' : [90,85,80,75,70,65,60,55,50,45,40]},
          { 'channels'   : [i for i in range(25,29)],
            'thresholds' : [145,150,155,160,165,170,175,180,185]}]

Boards = [7,8]
Nodes  = [0]

for scan in Scans:
    for chan in scan['channels']:
        for thold in scan['thresholds']:
            for n in Nodes:
                for b in Boards:
                    for r in range(2):
                        client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[chan].FastDac.set(thold)
                        client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[chan].SlowDac.set(thold)

                        # Turn off other channels
                        for other in range(0,36):
                            client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[other].FastTrigEnable.setDisp('Disable')
                            client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[other].SlowTrigEnable.setDisp('Disable')

                        # Turn on target channels
                        client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[chan].FastTrigEnable.setDisp('Enable')
                        client.MultiRenaRoot.Node[n].RenaArray.RenaBoard[b].Rena[r].Channel[chan].SlowTrigEnable.setDisp('Enable')

                # Configure boards
                client.MultiRenaRoot.Node[n].RenaArray.ConfigBoards()
                time.sleep(2)

            client.MultiRenaRoot.Initialize()
            time.sleep(1)

            # Open data file
            client.MultiRenaRoot.DataWriter.DataFile.set(f"/home/ril/slac_testing/ucsc-hn/software/scripts/{DataDir}/{chan:#02}_{thold:#03}.dat")
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


