import pyrogue as pr
import pyrogue.interfaces.simulation
import rogue
import surf.protocols.rssi
import surf.ethernet.udp
import RceG3
import ucsc_hn

class RenaNode(pr.Device):
    def __init__ (self, host, node=0, dataWriter=None, legacyWriter=None, emulate=False, **kwargs):
        super().__init__(description="FanInBoard Registers.", **kwargs)

        # Remote memory for FPGA reigsters
        if emulate:
            self._remMem = pr.interfaces.simulation.MemEmulate()
        else:
            self._remMem = rogue.interfaces.memory.TcpClient(host, 9000)

        # Core FPGA Registers
        self.add(RceG3.RceVersion(memBase=self._remMem))
        self.add(RceG3.RceEthernet(memBase=self._remMem))
        self.add(surf.ethernet.udp.UdpEngineServer(memBase=self._remMem,offset = 0xB0010000))
        self.add(surf.protocols.rssi.RssiCore(memBase=self._remMem,offset=0xB0020000))
        self.add(ucsc_hn.FanInRegs(memBase=self._remMem,offset=0xA0000000))

        self.add(ucsc_hn.RenaArray(host=host,nodeId=node,dataWriter=dataWriter,legacyWriter=legacyWriter,emulate=emulate))

        self._nodeId = node

    @property
    def nodeId(self):
        return self._nodeId

