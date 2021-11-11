import pyrogue as pr
import ucsc_hn
import threading
import time

class RunControl(pr.RunControl):
    """Special base class to control runs. """

    def __init__(self, *, hidden=True, states=None, cmd=None, **kwargs):
        super().__init__(hidden=hidden, rates={0 : 'Test Mode', 1 : 'Normal Mode'}, **kwargs)

    def _setRunState(self,value,changed):
        if changed:

            # Run enabled
            if value == 1:

                # Test Mode
                if self.runRate.get() == 0:
                    readEn  = 'Enable'
                    selRead = 'Disable'

                # Normal Mode
                else:
                    readEn  = 'Enable'
                    selRead = 'Enable'

                self._thread = threading.Thread(target=self._run)
                self._thread.start()

            # Run disabled
            else:
                readEn  = 'Disable'
                selRead = 'Disable'
                self._thread.join()
                self._thread = None

            for kn,n in self.root.getNodes(typ=ucsc_hn.RenaNode).items():
                for bn,b in n.RenaArray.getNodes(typ=ucsc_hn.RenaBoard).items():
                    b.ReadoutEnable.setDisp(readEn)
                    b.SelectiveRead.setDisp(selRead)

                n.RenaArray.ConfigReadout()

    def _run(self):
        self.runCount.set(0)

        while (self.runState.valueDisp() == 'Running'):
            time.sleep(1.0)

            total = 0

            for kn,n in self.root.getNodes(typ=ucsc_hn.RenaNode).items():
                total += n.RenaArray.DataDecoder.FrameCount.value()

            with self.runCount.lock:
                self.runCount.set(total)
