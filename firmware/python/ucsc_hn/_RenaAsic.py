import pyrogue as pr
import ucsc_hn

class RenaAsic(pr.Device):
    def __init__(self, rena, **kwargs):
        super().__init__(description="Rena Asic Configuration", **kwargs)

        # Geographic Data
        self._rena  = rena # Rena Index 0,1

        for i in range(36):
            self.add(ucsc_hn.RenaChannel(channel=i,name=f'Channel[{i}]'))


    @property
    def rena(self):
        return self._rena


    def _rxDiagnostic(self, rena):

        # Swap byte order
        cfgBytes = rena[::-1]

        # Extract channel
        chanRaw = cfgBytes[0] & 0x3F
        chan = 0

        # Bit swap
        for i in range(6):
            bit = (chanRaw >> (5-i)) & 0x1
            chan |= (bit << i)

        if chan < 36:
            self.Channel[chan]._rxDiagnostic(cfgBytes)

