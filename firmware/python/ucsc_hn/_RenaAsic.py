import pyrogue as pr
import ucsc_hn

class RenaAsic(pr.Device):
    def __init__(self, rena, **kwargs):
        super().__init__(description="Rena Asic Configuration", **kwargs)

        # Geographic Data
        self._rena  = rena # Rena Index 0,1

        for i in range(36):
            self.add(ucsc_hn.RenaChannel(channel=i,name=f'Channel[{i}]'))

        @self.command()
        def ResetHistogram():
            for k,v in self.getNodes(ucsc_hn.RenaChannel).items():
                v.ResetHistogram()

    @property
    def rena(self):
        return self._rena


    def _rxDiagnostic(self, rena):

        # Swap byte order
        cfgBytes = rena[::-1]

        # Extract channel
        chan =  (cfgBytes[6] << 1) & 0x3E
        chan += (cfgBytes[5] >> 5) & 0x01

        if chan < 36:
            self.Channel[chan]._rxDiagnostic(cfgBytes)

