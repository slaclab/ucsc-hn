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

        self.add(ucsc_hn.RenaNode(host=host,name='Node[0]'))
        self.add(ucsc_hn.DataWriter())
        self.add(ucsc_hn.RunControl())

        self.LoadConfig.replaceFunction(self._loadConfig)

    def _loadConfig(self,arg):
        self.loadYaml(name=arg,
                      writeEach=False,
                      modes=['RW','WO'],
                      incGroups=None,
                      excGroups='NoConfig')


        for kn,n in self.getNodes(typ=ucsc_hn.RenaNode).items():
            n.RenaArray.ConfigBoards()

