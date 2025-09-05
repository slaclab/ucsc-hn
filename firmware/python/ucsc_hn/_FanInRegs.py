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
            hidden       = True,
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

        self.add(pr.RemoteCommand(
            name         = 'MmcmReset',
            description  = 'Mmcm Reset Pulse',
            offset       = 0x014,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            function     = pr.Command.toggle,
        ))

        self.add(pr.RemoteCommand(
            name         = 'FpgaProg',
            description  = 'FPGA Program',
            offset       = 0x018,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            function     = pr.Command.toggle,
        ))

        self.add(pr.RemoteVariable(
            name         = 'SysClockCount',
            description  = 'System clock counter',
            offset       = 0x020,
            bitSize      = 32,
            bitOffset    = 0x00,
            base         = pr.UInt,
            mode         = 'RO',
        ))

        self.add(pr.RemoteVariable(
            name         = 'RenaClockCount',
            description  = 'Rena clock counter',
            offset       = 0x024,
            bitSize      = 32,
            bitOffset    = 0x00,
            base         = pr.UInt,
            mode         = 'RO',
        ))

        self.add(pr.RemoteVariable(
            name         = 'MmcmLockd',
            description  = 'MMCM Locked Status',
            offset       = 0x028,
            bitSize      = 1,
            bitOffset    = 0x00,
            base         = pr.UInt,
            mode         = 'RO',
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

        for i in range(1,31):
            self.add(pr.RemoteVariable(
                name         = f'OFlowCount[{i}]',
                description  = 'Overflow Count',
                offset       = 0x300 + (i-1)*4,
                bitSize      = 32,
                bitOffset    = 0x00,
                disp         = '{:#}',
                base         = pr.UInt,
                mode         = 'RO',
            ))

    def initialize(self):
        self.SendReset()

    def countReset(self):
        self.CountReset()
        super().countReset()

    def hardReset(self):
        self.FpgaProg()
        super().hardReset()

