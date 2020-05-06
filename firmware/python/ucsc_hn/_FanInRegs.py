import pyrogue as pr
import rogue

class FanInRegs(pr.Device):
    def __init__ (self, **kwargs):
        super().__init__(description="FanInBoard Registers.", **kwargs)

        self.add(pr.RemoteVariable(
            name         = 'ChanEnable',
            description  = 'Serial Channel Enable',
            offset       = 0x004,
            bitSize      = 32,
            bitOffset    = 0x00,
            base         = pr.UInt,
            mode         = 'RW',
        ))

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

        self.add(pr.RemoteCommand(
            name         = 'SendReset',
            description  = 'Send Reset Pulse',
            offset       = 0x010,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            function     = lambda cmd: cmd.post(1)
        ))

        for i in range(1,31):
            self.add(pr.RemoteVariable(
                name         = f'RxPackets[{i}]',
                description  = 'Receive Packets',
                offset       = 0x100 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                disp         = '{:#}',
                base         = pr.UInt,
                mode         = 'RO',
            ))

        for i in range(1,31):
            self.add(pr.RemoteVariable(
                name         = f'DropBytes[{i}]',
                description  = 'Dropped Bytes',
                offset       = 0x200 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                disp         = '{:#}',
                base         = pr.UInt,
                mode         = 'RO',
            ))

