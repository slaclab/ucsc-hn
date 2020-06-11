import pyrogue.interfaces
import time

client = pyrogue.interfaces.VirtualClient('localhost',9099)

print(f"Time= {client.MultiRenaRoot.LocalTime.get()}")

# Changing dac values
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].FastDac.set(100)
#client.MultiRenaRoot.Node[0].RenaArray.RenaBoard[7].Rena[0].Channel[0].SlowDac.set(100)

