import pyrogue
import pyrogue.protocols
import pyrogue.utilities
import pyrogue.utilities.prbs
import rogue
import surf.protocols.pgp as pgp
import surf.protocols.batcher
import surf.protocols.ssi
import surf.ethernet.udp
import RceG3
import ucsc_hn

class RateTestRoot(pyrogue.Root):

    def __init__(self,host=[]):

        pyrogue.Root.__init__(self,name='RateTestRoot',description='tester')

        self._remMem = rogue.interfaces.memory.TcpClient(host[0], 9000)

        self.add(surf.ethernet.udp.UdpEngineServer(memBase=self._remMem,offset = 0xB0010000))
        self.add(surf.protocols.rssi.RssiCore(memBase=self._remMem,offset=0xB0020000))
        self.add(surf.protocols.ssi.SsiPrbsTx(memBase=self._remMem, offset=0xA0000000))

        self._remRssi = pyrogue.protocols.UdpRssiPack(port=8192, host=host[0], packVer=2)
        self.add(self._remRssi)

        batch = rogue.protocols.batcher.SplitterV1()
        self.addProtocol(batch)

        pyrogue.streamConnect(self._remRssi.application(0),batch)

        prbs = pyrogue.utilities.prbs.PrbsRx()
        self.add(prbs)
        pyrogue.streamConnect(batch,prbs)

