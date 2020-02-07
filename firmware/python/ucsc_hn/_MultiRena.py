import pyrogue as pr
import rogue
import surf.protocols.pgp as pgp
import surf.protocols.batcher
import surf.protocols.ssi
import surf.protocols.rssi
import surf.ethernet.udp
import RceG3

class MultiRena(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="MutiRena Registers.", **kwargs)

        self.add(RceG3.RceVersion())
        self.add(RceG3.RceEthernet())
        self.add(surf.ethernet.udp.UdpEngineServer(offset = 0xB0010000))
        self.add(surf.protocols.rssi.RssiCore(offset=0xB0002000))
        self.add(surf.protocols.ssi.SsiPrbsTx(offset=0xA0000000))

