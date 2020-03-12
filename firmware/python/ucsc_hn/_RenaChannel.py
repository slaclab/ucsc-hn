import pyrogue as pr


def setValueToBits(bits, lsb, num, value):
    newBits = [int(x) for x in '{:0{width}b}'.format(value, width=num)[::-1]]

    bits[lsb:lsb+num] = newBits


def getValueFromBits(bits, lsb, num):
    getBits = bits[lsb:lsb+num]

    return int(''.join([f'{i}' for i in getBits[::-1]]),2)


class RenaChannel(pr.Device):
    def __init__(self, channel, **kwargs):
        super().__init__(description="Rena Channel Configuration", **kwargs)

        self._channel = channel # Rena Channel

        # Shift Bit 34
        self.add(pr.LocalVariable(name='FbResistor',
                                  value=0,
                                  mode='RW',
                                  enum={0:'200MOhm',1:'1.2 GOhm'},
                                  description='Channel Feedback Resistor Value'))

        # Shift Bit 33
        self.add(pr.LocalVariable(name='TestInputEnable',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Disable'},
                                  description='Channel Test Input Enable'))

        # Bit 32
        self.add(pr.LocalVariable(name='FastChanPowerDown',
                                  value=0,
                                  mode='RW',
                                  enum={0:'PowerOff',1:'PowerOn'},
                                  description='Channel Fast Path Power Down'))

        # Bit 31
        self.add(pr.LocalVariable(name='FbType',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Res. Mult.',1:'FET'},
                                  description='Channel Feedback Type'))

        # Bit 30:29
        self.add(pr.LocalVariable(name='Gain',
                                  value=0,
                                  mode='RW',
                                  enum={0:'1.6',1:'1.8',2:'2.3',3:'5.0'},
                                  description='Channel Gain'))

        # Bit 28
        self.add(pr.LocalVariable(name='PowerDown',
                                  value=0,
                                  mode='RW',
                                  enum={0:'PowerOff',1:'PowerOn'},
                                  description='Channel Power Down'))

        # Bit 27
        self.add(pr.LocalVariable(name='PoleZero',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Channel Pole Zero Cancellation'))

        # Bit 26
        self.add(pr.LocalVariable(name='FbCapacitor',
                                  value=0,
                                  mode='RW',
                                  enum={0:'15 fF',1:'60 fF'},
                                  description='Channel Feedback Capacitor Value'))

        # Bit 25, folows Polarity Bit

        # Bits 24:21
        self.add(pr.LocalVariable(name='ShapeTime',
                                  value=0,
                                  mode='RW',
                                  enum={0:'0.29 uS',
                                        1:'0.30 uS',
                                        2:'0.31 uS',
                                        3:'0.32 uS',
                                        4:'0.35 uS',
                                        5:'0.37 uS',
                                        6:'0.39 uS',
                                        7:'0.40 uS',
                                        8:'0.71 uS',
                                        9:'0.81 uS',
                                        10:'0.89 uS',
                                        11:'1.1 uS',
                                        12:'1.9 uS',
                                        13:'2.8 uS',
                                        14:'4.5 uS',
                                        15:'38 uS'},
                                  description='Channel Shape Time'))

        # Bit 20
        self.add(pr.LocalVariable(name='FbFetSize',
                                  value=0,
                                  mode='RW',
                                  enum={0:'450 um',1:'1000 um'},
                                  description='Channel Feedback Fet Size'))

        # Bits 19:12
        self.add(pr.LocalVariable(name='FastDac',
                                  value=0,
                                  mode='RW',
                                  description='Channel Fast Dac'))

        # Bit 11
        self.add(pr.LocalVariable(name='Polarity',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Negative',1:'Positive'},
                                  description='Channel Polarity'))

        # Bits 10:3
        self.add(pr.LocalVariable(name='SlowDac',
                                  value=0,
                                  mode='RW',
                                  description='Channel Slow Dac'))

        # Bit 2
        self.add(pr.LocalVariable(name='FastTrigEnable',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Channel Fast Trigger Enable'))

        # Bit 1
        self.add(pr.LocalVariable(name='SlowTrigEnable',
                                  value=0,
                                  mode='RW',
                                  enum={0:'Disable',1:'Enable'},
                                  description='Channel Slow Trigger Enable'))


    @property
    def channel(self):
        return self._channel


    @property
    def isFollower(self):

        if self.parent.parent.FollowerEn.value() and \
           self.parent.parent.FollowerAsic.value() == self.parent.Rena and \
           self.parent.parent.FollowerChannel.value() == self.channel:
            return True
        else:
            return False


    def configBytes(self):

        # Init a bit array
        cfgBits = [0] * 41

        # Set config bits in Rena ASIC order
        setValueToBits(cfgBits, 35, 6, self.channel)
        setValueToBits(cfgBits, 34, 1, self.FbResistor.value())
        setValueToBits(cfgBits, 33, 1, self.TestInputEnable.value())
        setValueToBits(cfgBits, 32, 1, self.FastChanPowerDown.value())
        setValueToBits(cfgBits, 31, 1, self.FbType.value())
        setValueToBits(cfgBits, 29, 2, self.Gain.value())
        setValueToBits(cfgBits, 28, 1, self.PowerDown.value())
        setValueToBits(cfgBits, 27, 1, self.PoleZero.value())
        setValueToBits(cfgBits, 26, 1, self.FbCapacitor.value())
        setValueToBits(cfgBits, 21, 4, self.ShapeTime.value())
        setValueToBits(cfgBits, 20, 1, self.FbFetSize.value())
        setValueToBits(cfgBits, 12, 8, self.FastDac.value())
        setValueToBits(cfgBits,  3, 8, self.SlowDac.value())

        # Fast and slow trigger should be disabled if the rena is in follower mode
        if self.isFollower:
            setValueToBits(cfgBits, 0, 1, 1) # Follower Bit 1 = 1
        else:
            setValueToBits(cfgBits, 2, 1, self.FastTrigEnable.value())
            setValueToBits(cfgBits, 1, 1, self.SlowTrigEnable.value())

        # Polarity controls two bits, 11 & 25
        if self.Polarity.value():
            setValueToBits(cfgBits, 25, 1, 1) # Bit 25 = VREFHI for negative
        else:
            setValueToBits(cfgBits, 11, 1, 1) # Bit 11 = Positive

        # Reverse Bit order
        cfgBits = cfgBits[::-1]

        # Append rena bit to array in position 41
        cfgBits.append(self.parent.rena)

        # Pack values to 6 bit chunks
        return bytearray([getValueFromBits(cfgBits,x*6,6) for x in range(7)])


    def buildChannelConfigSub(self):
        data = bytearray(13)

        data[0] = 0xC0 # Packet start
        data[1] = 0x00 # Source address, unused
        data[2] = 0x00 # Dest addres, unused
        data[3] = 0x81 # Clear buffer

        data[4:11] = self.configBytes()

        data[11] = 0x45 # Send channel config
        data[12] = 0xFF # End of packet

        # Return the data
        return data

