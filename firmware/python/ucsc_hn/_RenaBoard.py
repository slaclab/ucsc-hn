import pyrogue as pr
import ucsc_hn

class RenaBoard(pr.Device):
    def __init__(self, board, **kwargs):
        super().__init__(description="Rena Board Configuration", **kwargs)

        # Geographic Data
        self._board = board # Rena FPGA

        for i in range(2):
            self.add(ucsc_hn.RenaAsic(rena=i,name=f'Rena[{i}]'))

        self.add(pr.LocalVariable(name='ReadoutEnable',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Readout Enable'))

        self.add(pr.LocalVariable(name='ForceTrig',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Force Trigger Enable'))

        self.add(pr.LocalVariable(name='SerialNumber',
                                  value=0,
                                  mode='RW',
                                  description='Rena Board Serial Number'))

        self.add(pr.LocalVariable(name='OrMode',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Rena Board OR Mode'))

        self.add(pr.LocalVariable(name='SelectiveRead',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Channel Selective Read'))

        self.add(pr.LocalVariable(name='IntermediateBoard',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Even',1:'Odd',2:'Debug'},
                                  description='Intermediate Board'))

        self.add(pr.LocalVariable(name='FollowerEn',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Follower Enable'))

        self.add(pr.LocalVariable(name='FollowerAsic',
                                  value=0,
                                  mode='RW',
                                  description='Follower ASIC'))

        self.add(pr.LocalVariable(name='FollowerChannel',
                                  value=0,
                                  mode='RW',
                                  description='Follower Channel'))

        self.add(pr.LocalVariable(name='DiagMessageCount',
                                  value=0,
                                  mode='RO',
                                  pollInterval=1.0,
                                  description='Diagnostic message Count'))

        self.add(pr.LocalVariable(name='DiagMessageError',
                                  value=0,
                                  mode='RO',
                                  pollInterval=1.0,
                                  description='Diagnostic message Error Field'))

        @self.command()
        def ConfigBoard():
            for data in self.buildBoardConfigMessage(True):
                self.parent.sendData(data)

        @self.command()
        def ConfigReadout():
            for data in self.buildReadoutModeMessage():
                self.parent.sendData(data)

    @property
    def board(self):
        return self._board


    def buildBoardIdSub(self,bcast=False):
        data = bytearray(5)
        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer

        if bcast:
            data[2] = 0x3f # Broadcast
        else:
            data[2] = self.board & 0x3F # Rena Board address

        data[3] = 0x83 # Store address
        data[4] = 0xFF # End of packet

        return data


    def buildReadoutEnableSub(self,enable):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer

        if enable or self.ReadoutEnable.value():
            data[2] = 0x03

        data[3] = 0x49
        data[4] = 0xFF  # End of packaget

        return data


    def buildOrModeSub(self,enable):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer

        if enable or self.OrMode.value():
            data[2] = 0x03

        data[3] = 0x46
        data[4] = 0xFF  # End of packaget

        return data


    def buildForceTriggerSub(self,enable):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer

        if enable or self.ForceTrig.value():
            data[2] = 0x03

        data[3] = 0x47
        data[4] = 0xFF  # End of packaget

        return data

    def buildSelectiveReadSub(self):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer

        if self.SelectiveRead.value():
            data[2] = 0x01

        data[3] = 0x48
        data[4] = 0xFF  # End of packaget

        return data


    def buildIntermediateBoardSub(self):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer
        data[2] = self.IntermediateBoard.value() & 0x3f
        data[3] = 0x4a
        data[4] = 0xFF  # End of packaget

        return data


    def buildDiagnosticSub(self):
        data = bytearray(5)

        data[0] = 0xC0 # Packet start
        data[1] = 0x81 # Clear buffer
        data[2] = self.board & 0x3F # Rena Board address
        data[3] = 0x4E
        data[4] = 0xFF # End of packet

        return data


    def buildFollowerConfigSub(self):

        if self.FollowerEn.value():
            data = bytearray(7)

            data[0] = 0xC0 # Packet start
            data[1] = 0x81 # Clear buffer

            if self.FollowerAsic.value() == 0:
                data[2] = 0x01
            else:
                data[2] = 0x02

            data[3] = self.FollowerChannel.value() & 0x3F
            data[4] = 0x00 # Number of times to toggle TCLK 0 for PHA, 1 for U?, 2 for V?
            data[5] = 0x4D
            data[6] = 0xFF # End of packet

            return data

        else:
            data = bytearray(5)

            data[0] = 0xC0 # Packet start
            data[1] = 0x81 # Clear buffer
            data[2] = 0x3F # Turn off follower mode
            data[3] = 0x4D
            data[4] = 0xFF # End of packet

            return data


    def buildForceTriggerMessage(self,enable):
        yield self.buildBoardIdSub()
        yield self.buildForceTrigger(enable)
        yield self.buildReadoutEnableSub(enable)


    def buildReadoutModeMessage(self):
        yield self.buildBoardIdSub()
        yield self.buildReadoutEnableSub(False)
        yield self.buildOrModeSub(False)
        yield self.buildForceTriggerSub(False)
        yield self.buildSelectiveReadSub()
        yield self.buildIntermediateBoardSub()


    def buildBoardConfigMessage(self,diagEnable):
        yield self.buildBoardIdSub()
        yield self.buildReadoutEnableSub(False)
        yield self.buildOrModeSub(False)
        yield self.buildForceTriggerSub(False)
        yield self.buildSelectiveReadSub()
        yield self.buildIntermediateBoardSub()
        yield self.buildFollowerConfigSub()
        for channel in range(36):
            for rena in range(2):
                yield self.buildBoardIdSub()
                yield self.node(f'Rena[{rena}]').node(f'Channel[{channel}]').buildChannelConfigSub()
            if diagEnable:
                yield self.buildDiagnosticSub()


    def buildBoardDiagMessage(self):
        yield self.buildBoardIdSub()
        yield self.buildDiagnosticSub()


    def _rxDiagnostic(self, rena0, rena1, eBits):
        self.Rena[0]._rxDiagnostic(rena0[0:7])
        self.Rena[1]._rxDiagnostic(rena1[0:7])

        orTrig0 = (rena0[7] >> 5) & 0x1
        orTrig1 = (rena1[7] >> 5) & 0x1
        orExp = self.OrMode.value()

        forceTrig0 = (rena0[7] >> 4) & 0x1
        forceTrig1 = (rena1[7] >> 4) & 0x1
        forceExp = self.ForceTrig.value()

        readEn0 = (rena0[7] >> 3) & 0x1
        readEn1 = (rena1[7] >> 3) & 0x1
        readExp = self.ReadoutEnable.value()

        fModeEn0 = (rena0[7] >> 2) & 0x1
        fModeEn1 = (rena1[7] >> 2) & 0x1

        fModeChan0  = (rena0[7] << 4) & 0x30
        fModeChan0 |= (rena0[8] >> 2) & 0x0F

        fModeChan1  = (rena1[7] << 4) & 0x30
        fModeChan1 |= (rena1[8] >> 2) & 0x0F
        fModeChanExp = self.FollowerChannel.value() if self.FollowerEn.value() == 1 else 63

        fModeEnExp0 = 1 if ((self.FollowerEn.value() == 1) and (self.FollowerAsic.value() == 0)) else 0
        fModeEnExp1 = 1 if ((self.FollowerEn.value() == 1) and (self.FollowerAsic.value() == 1)) else 0

        if (orTrig0 != orTrig1) or (orTrig0 != orExp):
            raise(Exception(f"Diagnostic message, OrTrig setting mismatch for board {self.board}. Rena0={orTrig0}, Rena1={orTrig1}, Cfg={orExp}"))

        if (forceTrig0 != forceTrig1) or (forceTrig0 != forceExp):
            raise(Exception(f"Diagnostic message, ForceTrig setting mismatch for board {self.board}. Rena0={forceTrig0}, Rena1={forceTrig1}, Cfg={forceExp}"))

        if (readEn0 != readEn1) or (readEn0 != readExp):
            raise(Exception(f"Diagnostic message, ReadoutEnable setting mismatch for board {self.board}. Rena0={readEn0}, Rena1={readEn1}, Cfg={readExp}"))

        if (fModeChan0 != fModeChan1) or (fModeChan0 != fModeChanExp):
            raise(Exception(f"Diagnostic message, FollowerChannel setting mismatch for board {self.board}. Rena0={fModeChan0}, Rena1={fModeChan1}, Cfg={fModeChanExp}"))

        if fModeEn0 != fModeEnExp0:
            raise(Exception(f"Diagnostic message, FollowerModeEnable Asic setting mismatch for board {self.board} rena 0"))

        if fModeEn1 != fModeEnExp1:
            raise(Exception(f"Diagnostic message, FollowerModeEnable Asic setting mismatch for board {self.board} rena 1"))


        errBits = eBits[0] | (eBits[1] << 6) | (eBits[2] << 12) | (eBits[3] << 18) | (eBits[4] << 24)
        self.DiagMessageError.set(errBits)

        with self.DiagMessageCount.lock:
            self.DiagMessageCount.set(self.DiagMessageCount.value() + 1,write=False)
