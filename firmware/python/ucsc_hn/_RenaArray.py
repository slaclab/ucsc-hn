import pyrogue as pr
import ucsc_hn
import time
import rogue.interfaces.stream as ris

class RenaArray(pr.Device,ris.Master,ris.Slave):
    def __init__(self, host, **kwargs):
        pr.Device.__init__(self,description="FanInBoard Registers.", **kwargs)
        ris.Master.__init__(self)
        ris.Slave.__init__(self)

        # RSSI For interface to RENA Boards
        self._remRssi = pr.protocols.UdpRssiPack(port=8192, host=host, packVer=2)
        self.add(self._remRssi)
        pr.streamConnectBiDir(self, self._remRssi.application(0))

        for i in range(30):
            self.add(ucsc_hn.RenaBoard(board=i, name=f'RenaBoard[{i}]'))


        @self.command()
        def ConfigBoards():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ConfigBoard()


        @self.command()
        def PingBoards():
            data = bytearray(5)

            data[0] = 0xC0 # Packet start
            data[1] = 0x81 # Clear buffer
            data[2] = 0x3F # Rena broadcast address
            data[3] = 0x4E
            data[4] = 0xFF # End of packet

            self.sendData(data)


    def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        pass

    def verifyBlocks(self, recurse=True, variable=None, checkEach=False):
        pass

    def readBlocks(self, recurse=True, variable=None, checkEach=False):
        pass

    def checkBlocks(self, recurse=True, variable=None):
        pass


    def sendData(self, data):
        #print('Sending data:' + ''.join(' {:02x}'.format(x) for x in data))

        frame = self._reqFrame(len(data),True)
        frame.write(data,0)
        self._sendFrame(frame)


    def _acceptFrame(self, frame):
        data = bytearray(frame.getPayload())
        frame.read(data,0)

        print('Got data:' + ''.join(' {:02x}'.format(x) for x in data))


