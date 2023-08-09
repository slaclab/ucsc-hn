import pyrogue
import ucsc_hn
import time
import rogue.interfaces.stream as ris
import crc8
import ucsc_hn_lib
import rogue.interfaces.stream
import rogue.protocols.batcher

class RenaArray(pyrogue.Device,ris.Master,ris.Slave):
    def __init__(self, host, nodeId, dataWriter=None, legacyWriter=None, emulate=False, **kwargs):
        pyrogue.Device.__init__(self,description="FanInBoard Registers.", **kwargs)
        ris.Master.__init__(self)
        ris.Slave.__init__(self)

        dd = ucsc_hn.DataDecoder(nodeId=nodeId)
        self.add(dd)

        dataF = rogue.interfaces.stream.Filter(True,2)
        self.addProtocol(dataF)
        pyrogue.streamConnect(dd,dataF)
        pyrogue.streamConnect(dataF,dataWriter.getChannel(nodeId))

        legF = rogue.interfaces.stream.Filter(True,3)
        self.addProtocol(legF)
        pyrogue.streamConnect(dd,legF)
        pyrogue.streamConnect(legF,legacyWriter.getChannel(nodeId))

        diagF = rogue.interfaces.stream.Filter(True,1)
        self.addProtocol(diagF)
        pyrogue.streamConnect(dd,diagF)
        pyrogue.streamConnect(diagF,self)

        fifo = ucsc_hn.Fifo(name='TestFifo',description='Test Fifo', maxDepth=10000)
        self.add(fifo)

        # RSSI For interface to RENA Boards
        if emulate is False:
            self._remRssi = pyrogue.protocols.UdpRssiPack(port=8192, host=host, packVer=2)
            self.add(self._remRssi)

            pyrogue.streamConnect(self._remRssi.application(0),fifo)

            pyrogue.streamConnect(fifo,dd)

            pyrogue.streamConnect(self,self._remRssi.application(0))

        for i in range(1,31):
            self.add(ucsc_hn.RenaBoard(board=i, name=f'RenaBoard[{i}]'))

        self.add(pyrogue.LocalVariable(name='DiagMessageCount',
                                  value=0,
                                  mode='RO',
                                  pollInterval=1.0,
                                  description='Diagnostic message Count'))

        # Store histogram flags
        self.add(pyrogue.LocalVariable(name='DoHistogram',
                                  value=False,
                                  mode='RW',
                                  description='Store Histograms'))

        @self.command()
        def ConfigBoards():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ConfigBoard()

        @self.command()
        def ConfigReadout():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ConfigReadout()

        @self.command()
        def ResetHistogram():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ResetHistogram()

        @self.command()
        def PingBoards():
            data = bytearray(5)

            data[0] = 0xC0 # Packet start
            data[1] = 0x81 # Clear buffer
            data[2] = 0x3F # Rena broadcast address
            data[3] = 0x4E
            data[4] = 0xFF # End of packet

            self.sendData(data)


    def countReset(self):
        self.DiagMessageCount.set(0)
        super().countReset()

    def sendData(self, data):
        #print('Sending data:' + ''.join(' {:02x}'.format(x) for x in data))

        frame = self._reqFrame(len(data),True)
        frame.write(data,0)
        self._sendFrame(frame)


    def _acceptFrame(self, frame):
        data = bytearray(frame.getPayload())
        frame.read(data,0)

        if data[0] != 0xc4:
            return False

        if len(data) != 28 or data[27] != 0xFF:
            print("Diagnostic packet length mismatch. Got {len(data)} expected 28")
            return True

        addr  = data[1] >> 1
        rena0 = data[2:11]  #  9 * 6 = 54 bits, 42 bits are valid
        rena1 = data[11:20]
        eBits = data[20:25] # 5 Bytes
        crc   = data[25] << 4 | data[26]

        hash = crc8.crc8()
        hash.update(data[0:25])

        good = (crc == hash.digest()[0])

        if not good:
            print("Bad diagnostic packet CRC")
            return True

        if addr == 0 or addr > 30:
            print(f"Bad diagnostic packet address {addr}")
            return True

        self.RenaBoard[addr]._rxDiagnostic(rena0, rena1, eBits)

        with self.DiagMessageCount.lock:
            self.DiagMessageCount.set(self.DiagMessageCount.value() + 1,write=False)

        return True

