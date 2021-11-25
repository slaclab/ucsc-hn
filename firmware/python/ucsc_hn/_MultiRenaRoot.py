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
    def __init__(self,host=[],pollEn=True,emulate=False):
        pyrogue.Root.__init__(self,name='MultiRenaRoot',description='tester', pollEn=pollEn)

        dw = ucsc_hn.DataWriter()
        self.add(dw)

        lw = ucsc_hn.LegacyWriter()
        self.add(lw)

        for i in range(len(host)):
            self.add(ucsc_hn.RenaNode(host=host[i],name=f'Node[{i}]',node=i,dataWriter=dw,legacyWriter=lw,emulate=emulate))

        self.add(ucsc_hn.RunControl())

        self.LoadConfig.replaceFunction(self._loadConfig)

        for node in range(len(host)):
            for rena in range(1,31):

                self.add(pyrogue.LinkVariable(name=f'DiagCount_{node}_{rena}',
                                              mode='RO',
                                              variable=self.Node[node].RenaArray.RenaBoard[rena].DiagMessageCount,
                                              guiGroup='DiagMessageCount'))

        self.add(pyrogue.LocalCommand(name='SaveOldConfig', value='',
                                      function=self._storeOldConfig,
                                      hidden=False,
                                      description='Store old configuration to a file'))

    def _loadConfig(self,arg):
        self.loadYaml(name=arg,
                      writeEach=False,
                      modes=['RW','WO'],
                      incGroups=None,
                      excGroups='NoConfig')

        for kn,n in self.getNodes(typ=ucsc_hn.RenaNode).items():
            n.RenaArray.ConfigBoards()


    def _storeOldConfig(self,arg):

        try:
            with open(arg,'w') as f:

                for nodeK,nodeV in self.getNodes(ucsc_hn.RenaNode).items():
                    for boardK,boardV in nodeV.RenaArray.getNodes(ucsc_hn.RenaBoard).items():
                        for renaK,renaV in boardV.getNodes(ucsc_hn.RenaAsic).items():
                            for chanK,chanV in renaV.getNodes(ucsc_hn.RenaChannel).items():
                                chanV._writeLegacyConfig(f,nodeV.nodeId,boardV.board,renaV.rena)

        except Exception as e:
            pyrogue.logException(self._log,e)

