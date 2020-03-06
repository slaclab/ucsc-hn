import pyrogue as pr
import rogue

class FanInRegs(pr.Device):
    def __init__ (self, host, **kwargs):
        super().__init__(description="FanInBoard Registers.", **kwargs)

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

        for i in range(1,31):
            self.add(pr.RemoteVariable(
                name         = 'RxPackets',
                description  = 'Receive Packets',
                offset       = 0x100 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                base         = pr.UInt,
                mode         = 'RO',
            ))

        for i in range(1,31):
            self.add(pr.RemoteVariable(
                name         = 'DropBytes',
                description  = 'Dropped Bytes',
                offset       = 0x200 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                base         = pr.UInt,
                mode         = 'RO',
            ))

