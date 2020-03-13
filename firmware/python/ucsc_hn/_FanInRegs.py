import pyrogue as pr
import rogue

class FanInRegs(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="FanInBoard Registers.", **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'SerialBits',
            description  = 'Serial Bit Status',
            offset       = 0x008,
            bitSize      = 32,
            bitOffset    = 0x00,
            base         = pr.UInt,
            mode         = 'RO',
        ))

        self.add(pr.RemoteCommand(
            name         = 'CountReset',
            description  = 'Reset Counters',
            offset       = 0x00C,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            function     = lambda cmd: cmd.post(1),
            hidden       = False,
        ))

        for i in range(1,2):
            self.add(pr.RemoteVariable(
                name         = f'RxPackets[{i}]',
                description  = 'Receive Packets',
                offset       = 0x100 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                base         = pr.UInt,
                mode         = 'RO',
            ))

        for i in range(1,2):
            self.add(pr.RemoteVariable(
                name         = f'DropBytes[{i}]',
                description  = 'Dropped Bytes',
                offset       = 0x200 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                base         = pr.UInt,
                mode         = 'RO',
            ))

        for i in range(1,2):
            self.add(pr.RemoteVariable(
                name         = f'OverSize[{i}]',
                description  = 'OverSize Frames',
                offset       = 0x300 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                base         = pr.UInt,
                mode         = 'RO',
            ))

