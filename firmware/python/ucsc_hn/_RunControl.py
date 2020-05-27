import pyrogue as pr
import ucsc_hn

class RunControl(pr.RunControl):
    """Special base class to control runs. """

    def __init__(self, *, hidden=True, states=None, cmd=None, **kwargs):
        super().__init__(hidden=hidden, rates={0 : 'Self Triggered'}, **kwargs)

    def _setRunState(self,value,changed):
        if changed:

            if value == 1:
                state = 'Enable'
            else:
                state = 'Disable'

            for kn,n in self.root.getNodes(typ=ucsc_hn.RenaNode).items():
                for bn,b in n.RenaArray.getNodes(typ=ucsc_hn.RenaBoard).items():
                    b.ReadoutEnable.setDisp(state)

                n.RenaArray.ConfigReadout()

    def _run(self):
        pass

    def _increment(self):
        with self.runCount.lock:
            self.runCount.set(self.runCount.value() + 1, write=False)
