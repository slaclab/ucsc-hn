
import pyrogue
import rogue

pyrogue.addLibraryPath('../../firmware/submodules/rce-gen3-fw-lib/python')
pyrogue.addLibraryPath('../../firmware/submodules/surf/python')
pyrogue.addLibraryPath('../../firmware/python')
pyrogue.addLibraryPath('../python')

import ucsc_hn
import ucsc_hn_lib
import sys

class RenaArrayEmulator(pyrogue.Root):
    def __init__(self, dataFile, **kwargs):
        pyrogue.Root.__init__(self,description="Rena Array Emulator", **kwargs)

        dw = ucsc_hn.DataWriter()
        self.add(dw)

        lw = ucsc_hn.LegacyWriter()
        self.add(lw)

        dd = ucsc_hn.DataDecoder(nodeId=0)
        self.add(dd)

        dataF = rogue.interfaces.stream.Filter(True,3)
        self.addProtocol(dataF)
        pyrogue.streamConnect(dd,dataF)

        dataFifo = ucsc_hn.Fifo(name='DataFifo',description='Data Fifo', maxDepth=1000, noCopy=True)
        self.add(dataFifo)
        pyrogue.streamConnect(dataF,dataFifo)
        pyrogue.streamConnect(dataFifo,dw.getChannel(0))

        legF = rogue.interfaces.stream.Filter(True,2)
        self.addProtocol(legF)
        pyrogue.streamConnect(dd,legF)

        legFifo = ucsc_hn.Fifo(name='LegFifo',description='Leg Fifo', maxDepth=1000, noCopy=True)
        self.add(legFifo)
        pyrogue.streamConnect(legF,legFifo)
        pyrogue.streamConnect(legFifo,lw.getChannel(0))

        fifo = ucsc_hn.Fifo(name='TestFifo',description='Test Fifo', maxDepth=1000, noCopy=True)
        self.add(fifo)

        emul = ucsc_hn.RenaDataEmulator(dataFile=dataFile)
        self.add(emul)

        pyrogue.streamConnect(emul,fifo)
        pyrogue.streamConnect(fifo,dd)

        # Add zmq server
        self.zmqServer = pyrogue.interfaces.ZmqServer(root=self, addr='*', port=0)
        self.addInterface(self.zmqServer)

if __name__ == "__main__":

    with RenaArrayEmulator(dataFile=sys.argv[1]) as root:
        import pyrogue.pydm
        #pyrogue.pydm.runPyDM(serverList=root.zmqServer.address)
        pyrogue.pydm.runPyDM(root=root)

