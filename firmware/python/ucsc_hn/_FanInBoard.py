import pyrogue as pr
import rogue
import surf.protocols.rssi
import surf.ethernet.udp
import RceG3
import ucsc_hn

class FanInBoard(pr.Device):
    def __init__ (self, host, **kwargs):
        super().__init__(description="FanInBoard Registers.", **kwargs)

        # Remote memory for FPGA reigsters
        self._remMem = rogue.interfaces.memory.TcpClient(host, 9000)

        # Core FPGA Registers
        self.add(RceG3.RceVersion(memBase=self._remMem))
        self.add(RceG3.RceEthernet(memBase=self._remMem))
        self.add(surf.ethernet.udp.UdpEngineServer(memBase=self._remMem,offset = 0xB0010000))
        self.add(surf.protocols.rssi.RssiCore(memBase=self._remMem,offset=0xB0020000))
        self.add(ucsc_hn.FanInRegs(memBase=self._remMem,offset=0xA0000000))

        self.add(ucsc_hn.RenaArray(host=host))
