import pyrogue as pr
import ucsc_hn
import threading
import time

class RunControl(pr.RunControl):
    """Special base class to control runs. """

    def __init__(self, *, hidden=True, states=None, cmd=None, **kwargs):
        super().__init__(hidden=hidden, rates={0 : 'Self Triggered'}, **kwargs)

    def _setRunState(self,value,changed):
        if changed:

            if value == 1:
                state = 'Enable'
                self._thread = threading.Thread(target=self._run)
                self._thread.start()
            else:
                state = 'Disable'
                self._thread.join()
                self._thread = None

            for kn,n in self.root.getNodes(typ=ucsc_hn.RenaNode).items():
                for bn,b in n.RenaArray.getNodes(typ=ucsc_hn.RenaBoard).items():
                    b.ReadoutEnable.setDisp(state)

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
