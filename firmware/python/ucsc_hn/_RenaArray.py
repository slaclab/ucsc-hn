import pyrogue as pr
import ucsc_hn
import time
import rogue.interfaces.stream as ris
import crc8

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

        self.add(pr.LocalVariable(name='DiagMessageCount',
                                  value=0,
                                  mode='RO',
                                  pollInterval=1.0,
                                  description='Diagnostic message Count'))

        @self.command()
        def ConfigBoards():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ConfigBoard()

        @self.command()
        def ConfigReadout():
            for k,v in self.getNodes(ucsc_hn.RenaBoard).items():
                v.ConfigReadout()

        @self.command()
        def PingBoards():
            data = bytearray(5)

            data[0] = 0xC0 # Packet start
            data[1] = 0x81 # Clear buffer
            data[2] = 0x3F # Rena broadcast address
            data[3] = 0x4E
            data[4] = 0xFF # End of packet

            self.sendData(data)


    #def writeBlocks(self, force=False, recurse=True, variable=None, checkEach=False):
        #pass

    #def verifyBlocks(self, recurse=True, variable=None, checkEach=False):
        #pass

    #def readBlocks(self, recurse=True, variable=None, checkEach=False):
        #pass

    #def checkBlocks(self, recurse=True, variable=None):
        #pass


    def sendData(self, data):
        #print('Sending data:' + ''.join(' {:02x}'.format(x) for x in data))

        frame = self._reqFrame(len(data),True)
        frame.write(data,0)
        self._sendFrame(frame)


    def _acceptFrame(self, frame):
        data = bytearray(frame.getPayload())
        frame.read(data,0)

        l = frame.getPayload()

        #print(f'Got data {l}:' + ''.join(' {:02x}'.format(x) for x in data))

        if not self._parseDiagnostic(data):
            print(f'Got non diag data {l}:' + ''.join(' {:02x}'.format(x) for x in data))
            self._parseDataPacket(data)


    def _parseDiagnostic(self, data):
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


    def _parseDataPacket(self, data):

        # AND Mode
        if data[0] == 0xC8:
            readoutMode = 0

        # OR Mode
        elif data[0] == 0xC9:
            readoutMode = 1
        else:
            print(f"Uknown data data type: {data[0]:2x}")
            return False

        # Compute CRC
        hash = crc8.crc8()
        hash.update(data[0:-3])

        gotCrc  = data[-3] << 4 | data[-2]
        expCrc  = hash.digest()[0]

        if gotCrc != expCrc:
            print(f"Bad data packet CRC. Got={gotCrc}, exp={expCrc}")
            return False

        # First byte is rena id and board address
        renaId = data[1] & 0x1
        fpgaId = (data[1] >> 1) & 0x3F

        print("--------------------")
        print(f"board = {fpgaId}, rena = {renaId}")
        print(f"ReadoutMode = {readoutMode}")

        # Bytes 2 - 7 are the timestamp, 42 bits
        timeStamp = 0
        for i in range(2,8):
            timeStamp = timeStamp << 7
            timeStamp |= data[i]

        print(f"timestamp = {timeStamp}")

        # Bytes 8 - 13 are the fast trigger list for channels 35-0
        fastTriggerList = 0
        for i in range(8,14):
            fastTriggerList = fastTriggerList << 6
            fastTriggerList |= data[i]

        buffIdx = 14
        print(f"fastTriggerList = {fastTriggerList:08x}")

        # Bytes 14 - 19 are the slow trigger list for channels 35-0
        slowTriggerList = 0

        # OR Mode
        if readoutMode == 1:
            for i in range(14,20):
                slowTriggerList = slowTriggerList << 6
                slowTriggerList |= data[i]

            buffIdx = 20
            print(f"slowTriggerList = {slowTriggerList:08x}")

        # Remaining bytes are each channels PHA, U and V ADC values

        # Count the number of fast triggers
        fastCount = 0
        for i in range(0,36):
            if ((1 << i) & fastTriggerList) != 0:
                fastCount += 1

        print(f"fastCount = {fastCount}")

        # Count the number of slow triggers
        slowCount = 0

        # OR Mode
        if readoutMode == 1:
            for i in range(0,36):
                if ((1 << i) & slowTriggerList) != 0:
                    slowCount += 1

        print(f"slowCount = {slowCount}")

        # AND Mode
        if readoutMode == 0:
            expLength = 17 + (fastCount * 6)

        # OR Mode
        else:
            expLength = 23 + (fastCount * 4) + (slowCount * 2)

        if len(data) != expLength:
            print(f"Bad frame length expected {expLength} got {len(data)}")
            return False


        # Extract data
        for i in range(0,36):
            readPHA = False
            readUV  = False
            bit = 1 << i

            # AND Mode
            if readoutMode == 0:
                if (bit & fastTriggerList) != 0:
                    readPHA = True
                    readUV  = True

            # OR Mode
            else:
                if (bit & slowTriggerList) != 0:
                    readPHA = True
                if (bit & fastTriggerList) != 0:
                    readUV = True

            if readPHA or readUV:
                hitData = {'channel'    : i,
                           'fpgaId'     : fpgaId,
                           'renaId'     : renaId,
                           'nodeId'     : 0,
                           'polarity'   : 'Negative', # Get From Config
                           'timeStamp'  : timeStamp,
                           'triggerNum' : 0, # Add running trigger number, per frame rx
                           'PHA'        : -1,
                           'U'          : -1,
                           'V'          : -1 }

                # PHA is two bytes
                if readPHA:
                    hitData['PHA'] = data[buffIdx] << 6 | data[buffIdx+1]
                    buffIdx += 2

                if readUV:

                    # U is 2 bytes
                    hitData['U'] = data[buffIdx] << 6 | data[buffIdx+1]
                    buffIdx += 2

                    # V is 2 bytes
                    hitData['U'] = data[buffIdx] << 6 | data[buffIdx+1]
                    buffIdx += 2


