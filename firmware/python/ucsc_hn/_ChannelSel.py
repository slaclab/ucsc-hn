import pyrogue as pr

class ChannelSelect(pr.Device):
    def __init__(self, nodeCount, **kwargs):
        super().__init__(description="Channel Select Configuration", **kwargs)

        self._nodeCount = nodeCount

        ##############################
        # Select
        ##############################

        self.add(pr.LocalVariable(name='NodeSelect',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=self._nodeCount-1,
                                 description="Node Selection"))

        self.add(pr.LocalVariable(name='BoardSelect',
                                 value=1,
                                 mode='RW',
                                 minimum=1,
                                 maximum=30,
                                 description="Board Selection"))

        self.add(pr.LocalVariable(name='RenaSelect',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=1,
                                 description="Rena Selection"))

        self.add(pr.LocalVariable(name='ChannelSelect',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=35,
                                 description="Channel Selection"))

        ##############################
        # Copy Source / Dest Select
        ##############################

        self.add(pr.LocalVariable(name='NodeCopy',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=self._nodeCount-1,
                                 description="Node For Copy To/From"))

        self.add(pr.LocalVariable(name='BoardCopy',
                                 value=1,
                                 mode='RW',
                                 minimum=1,
                                 maximum=30,
                                 description="Board For Copy To/From"))

        self.add(pr.LocalVariable(name='RenaCopy',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=1,
                                 description="Rena For Copy To/From"))

        self.add(pr.LocalVariable(name='ChannelCopy',
                                 value=0,
                                 mode='RW',
                                 minimum=0,
                                 maximum=35,
                                 description="Channel For Copy To/From"))

        self.add(pr.Command(name='CopyChannelTo',
                            function=self._copyChannelTo,
                            description="Copy current selected channel to Copy Channel"))

        self.add(pr.Command(name='CopyChannelFrom',
                            function=self._copyChannelFrom,
                            description="Copy current selected channel from Copy Channel"))

        self.add(pr.Command(name='CopyBoardTo',
                            function=self._copyBoardTo,
                            description="Copy current selected board to Copy Channel"))

        self.add(pr.Command(name='CopyBoardFrom',
                            function=self._copyBoardFrom,
                            description="Copy current selected board from Copy Channel"))

        ##############################
        # Boards
        ##############################
        self._copyBoardList = [ 'ReadoutEnable',
                                'ForceTrig',
                                'OrMode',
                                'SelectiveRead',
                                'IntermediateBoard',
                                'FollowerEn',
                                'FollowerAsic',
                                'FollowerChannel']

        self.add(pr.LinkVariable(name='ReadoutEnable',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Readout Enable'))

        self.add(pr.LinkVariable(name='ForceTrig',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Force Trigger Enable'))

        self.add(pr.LinkVariable(name='OrMode',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Rena Board OR Mode'))

        self.add(pr.LinkVariable(name='SelectiveRead',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Channel Selective Read'))

        self.add(pr.LinkVariable(name='IntermediateBoard',
                                 mode='RW',
                                 enum={0:'Even',1:'Odd',2:'Debug'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Intermediate Board'))

        self.add(pr.LinkVariable(name='FollowerEn',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Follower Enable'))

        self.add(pr.LinkVariable(name='FollowerAsic',
                                 mode='RW',
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Follower ASIC'))

        self.add(pr.LinkVariable(name='FollowerChannel',
                                 mode='RW',
                                 groups=['BoardConfig','DoCopy'],
                                 linkedGet=self._boardGet,
                                 linkedSet=self._boardSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect],
                                 description='Follower Channel'))

        ##############################
        # Channel
        ##############################
        self._copyChanList = [ 'FbResistor',
                               'TestInputEnable',
                               'FastChanPowerDown',
                               'FbType',
                               'Gain',
                               'PowerDown',
                               'PoleZero',
                               'FbCapacitor',
                               'ShapeTime',
                               'FbFetSize',
                               'FastDac',
                               'Polarity',
                               'SlowDac',
                               'FastTrigEnable',
                               'SlowTrigEnable',
                               'PhaHistogram' ]

        self.add(pr.LinkVariable(name='FbResistor',
                                 mode='RW',
                                 enum={0:'200MOhm',1:'1.2 GOhm'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Feedback Resistor Value'))

        self.add(pr.LinkVariable(name='TestInputEnable',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Test Input Enable'))

        self.add(pr.LinkVariable(name='FastChanPowerDown',
                                 mode='RW',
                                 enum={0:'PowerOn',1:'PowerOff'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Fast Path Power Down'))

        self.add(pr.LinkVariable(name='FbType',
                                 mode='RW',
                                 enum={0:'Res. Mult.',1:'FET'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Feedback Type'))

        self.add(pr.LinkVariable(name='Gain',
                                 mode='RW',
                                 enum={0:'1.6',1:'1.8',2:'2.3',3:'5.0'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Gain'))

        self.add(pr.LinkVariable(name='PowerDown',
                                 mode='RW',
                                 enum={0:'PowerOn',1:'PowerOff'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Power Down'))

        self.add(pr.LinkVariable(name='PoleZero',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Pole Zero Cancellation'))

        self.add(pr.LinkVariable(name='FbCapacitor',
                                 mode='RW',
                                 enum={0:'15 fF',1:'60 fF'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Feedback Capacitor Value'))

        self.add(pr.LinkVariable(name='ShapeTime',
                                 mode='RW',
                                 enum={0:'0.29 uS',
                                       1:'0.30 uS',
                                       2:'0.31 uS',
                                       3:'0.32 uS',
                                       4:'0.35 uS',
                                       5:'0.37 uS',
                                       6:'0.39 uS',
                                       7:'0.40 uS',
                                       8:'0.71 uS',
                                       9:'0.81 uS',
                                       10:'0.89 uS',
                                       11:'1.1 uS',
                                       12:'1.9 uS',
                                       13:'2.8 uS',
                                       14:'4.5 uS',
                                       15:'38 uS'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Shape Time'))

        self.add(pr.LinkVariable(name='FbFetSize',
                                 mode='RW',
                                 enum={0:'450 um',1:'1000 um'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Feedback Fet Size'))

        self.add(pr.LinkVariable(name='FastDac',
                                 mode='RW',
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Fast Dac'))

        self.add(pr.LinkVariable(name='Polarity',
                                 mode='RW',
                                 enum={0:'Negative',1:'Positive'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Polarity'))

        self.add(pr.LinkVariable(name='SlowDac',
                                 mode='RW',
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Slow Dac'))

        self.add(pr.LinkVariable(name='FastTrigEnable',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Fast Trigger Enable'))

        self.add(pr.LinkVariable(name='SlowTrigEnable',
                                 mode='RW',
                                 enum={0:'Disable',1:'Enable'},
                                 groups=['ChannelConfig','DoCopy'],
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel Slow Trigger Enable'))

        self.add(pr.LinkVariable(name='PhaHistogram',
                                 mode='RW',
                                 groups=['ChannelConfig','DoCopy'],
                                 hidden=True,
                                 linkedGet=self._channelGet,
                                 linkedSet=self._channelSet,
                                 dependencies=[self.NodeSelect, self.BoardSelect, self.RenaSelect, self.ChannelSelect],
                                 description='Channel data histogram'))

    def _channelGet(self, *, var, read, check):
        node    = self.NodeSelect.get(read=False,check=False)
        board   = self.BoardSelect.get(read=False,check=False)
        rena    = self.RenaSelect.get(read=False,check=False)
        channel = self.ChannelSelect.get(read=False,check=False)
        varName = var.name

        return self.root.Node[node].RenaArray.RenaBoard[board].Rena[rena].Channel[channel].node(varName).get(read=read,check=check)

    def _channelSet(self, *, var, write, verify, check, value):
        node    = self.NodeSelect.get(read=False,check=False)
        board   = self.BoardSelect.get(read=False,check=False)
        rena    = self.RenaSelect.get(read=False,check=False)
        channel = self.ChannelSelect.get(read=False,check=False)
        varName = var.name

        self.root.Node[node].RenaArray.RenaBoard[board].Rena[rena].Channel[channel].node(varName).set(write=write,verify=verify,check=check,value=value)

    def _boardGet(self, *, var, read, check):
        node  = self.NodeSelect.get(read=False,check=False)
        board = self.BoardSelect.get(read=False,check=False)
        varName = var.name

        return self.root.Node[node].RenaArray.RenaBoard[board].node(varName).get(read=read,check=check)

    def _boardSet(self, *, var, write, verify, check, value):
        node  = self.NodeSelect.get(read=False,check=False)
        board = self.BoardSelect.get(read=False,check=False)
        varName = var.name

        self.root.Node[node].RenaArray.RenaBoard[board].node(varName).set(write=write,verify=verify,check=check,value=value)

    def _copyChannelTo(self):
        loc_node    = self.NodeSelect.get(read=False,check=False)
        loc_board   = self.BoardSelect.get(read=False,check=False)
        loc_rena    = self.RenaSelect.get(read=False,check=False)
        loc_channel = self.ChannelSelect.get(read=False,check=False)

        cpy_node    = self.NodeCopy.get(read=False,check=False)
        cpy_board   = self.BoardCopy.get(read=False,check=False)
        cpy_rena    = self.RenaCopy.get(read=False,check=False)
        cpy_channel = self.ChannelCopy.get(read=False,check=False)

        for varName,var in self.getNodes(typ=pr.Node, incGroups=['ChannelConfig']).items():
            if var.inGroup('DoCopy'):
                val = self.root.Node[loc_node].RenaArray.RenaBoard[loc_board].Rena[loc_rena].Channel[loc_channel].node(varName).get(read=False)
                self.root.Node[cpy_node].RenaArray.RenaBoard[cpy_board].Rena[cpy_rena].Channel[cpy_channel].node(varName).setDisp(val)

    def _copyChannelFrom(self):
        loc_node    = self.NodeSelect.get(read=False,check=False)
        loc_board   = self.BoardSelect.get(read=False,check=False)
        loc_rena    = self.RenaSelect.get(read=False,check=False)
        loc_channel = self.ChannelSelect.get(read=False,check=False)

        cpy_node    = self.NodeCopy.get(read=False,check=False)
        cpy_board   = self.BoardCopy.get(read=False,check=False)
        cpy_rena    = self.RenaCopy.get(read=False,check=False)
        cpy_channel = self.ChannelCopy.get(read=False,check=False)

        for varName,var in self.getNodes(typ=pr.Node, incGroups=['ChannelConfig']).items():
            if var.inGroup('DoCopy'):
                val = self.root.Node[cpy_node].RenaArray.RenaBoard[cpy_board].Rena[cpy_rena].Channel[cpy_channel].node(varName).get(read=False)
                self.root.Node[loc_node].RenaArray.RenaBoard[loc_board].Rena[loc_rena].Channel[loc_channel].node(varName).setDisp(val)

    def _copyBoardTo(self):
        loc_node    = self.NodeSelect.get(read=False,check=False)
        loc_board   = self.BoardSelect.get(read=False,check=False)

        cpy_node    = self.NodeCopy.get(read=False,check=False)
        cpy_board   = self.BoardCopy.get(read=False,check=False)

        for varName,var in self.getNodes(typ=pr.Node, incGroups=['BoardConfig','DoCopy']).items():
            if var.inGroup('DoCopy'):
                val = self.root.Node[loc_node].RenaArray.RenaBoard[loc_board].node(varName).get(read=False)
                self.root.Node[cpy_node].RenaArray.RenaBoard[cpy_board].node(varName).setDisp(val)

    def _copyBoardFrom(self):
        loc_node    = self.NodeSelect.get(read=False,check=False)
        loc_board   = self.BoardSelect.get(read=False,check=False)

        cpy_node    = self.NodeCopy.get(read=False,check=False)
        cpy_board   = self.BoardCopy.get(read=False,check=False)

        for varName,var in self.getNodes(typ=pr.Node, incGroups=['BoardConfig','DoCopy']).items():
            if var.inGroup('DoCopy'):
                val = self.root.Node[cpy_node].RenaArray.RenaBoard[cpy_board].node(varName).get(read=False)
                self.root.Node[loc_node].RenaArray.RenaBoard[loc_board].node(varName).setDisp(val)

    def initialize(self):
        super().initialize()

        # Link dependencies
        for node in range(self._nodeCount):
            for board in range(1,31):
                for rena in range(2):
                    for chan in range(36):
                        for var in self.getNodes(typ=pr.Node, incGroups=['BoardConfig']):
                            self.root.Node[node].RenaArray.RenaBoard[board].node(var).addListener(self.node(var))

        # Link dependencies
        for node in range(self._nodeCount):
            for board in range(1,31):
                for rena in range(2):
                    for chan in range(36):
                        for var in self.getNodes(typ=pr.Node, incGroups=['ChannelConfig']):
                            self.root.Node[node].RenaArray.RenaBoard[board].Rena[rena].Channel[channel].node(var).addListener(self.node(var))

