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

class MultiRenaRoot(pyrogue.Root):
    def __init__(self,host="",pollEn=True):
        pyrogue.Root.__init__(self,name='MultiRenaRoot',description='tester', pollEn=pollEn)

        self.add(ucsc_hn.FanInBoard(host=host))
        self.add(ucsc_hn.DataWriter())

