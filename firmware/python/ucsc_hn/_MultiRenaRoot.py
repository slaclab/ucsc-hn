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
    def __init__(self,host=[],pollEn=True):
        pyrogue.Root.__init__(self,name='MultiRenaRoot',description='tester', pollEn=pollEn)

        dw = ucsc_hn.DataWriter()
        self.add(dw)

        lw = ucsc_hn.LegacyWriter()
        self.add(lw)

        self.add(ucsc_hn.RenaNode(host=host[0],name='Node[0]',node=0,dataWriter=dw,legacyWriter=lw))
        self.add(ucsc_hn.RenaNode(host=host[1],name='Node[1]',node=1,dataWriter=dw,legacyWriter=lw))
        self.add(ucsc_hn.RunControl())

        self.LoadConfig.replaceFunction(self._loadConfig)

        for node in range(0,2):
            for rena in range(1,31):

                self.add(pyrogue.LinkVariable(name=f'DiagCount_{node}_{rena}',
                                              mode='RO',
                                              variable=self.Node[node].RenaArray.RenaBoard[rena].DiagMessageCount,
                                              guiGroup='DiagMessageCount'))

        self.add(pr.LocalCommand(name='SaveOldConfig', value='',
                                 function=self._storeOldConfig,
                                 hidden=False,
                                 description='Store old configuration to a file'))

    def _loadConfig(self,arg):
        self.loadYaml(name=arg,
                      writeEach=False,
                      modes=['RW','WO'],
                      incGroups=None,
                      excGroups='NoConfig')


    def _storeOldConfig(self,arg):

        try:
            with open(arg) as f:

                for node in self.getNodes(ucsc_hn.RenaNode):
                    for board in node.RenaArray.getNodes(ucsc_hn.RenaBoard):
                        for rena in board.getNodes(ucsc_hn.RenaAsic):
                            for chan in rena.getNodes(ucsh_hn.RenaChannel):
                                chan._writeLegacyConfig(f,node.nodeId,board.board,rena.rena)

        except Exception as e:
            pr.logException(self._log,e)

