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


