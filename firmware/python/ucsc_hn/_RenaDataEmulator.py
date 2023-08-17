#-----------------------------------------------------------------------------
# Title      : PyRogue Utilities base module
#-----------------------------------------------------------------------------
# Description:
# Module containing the utilities module class and methods
#-----------------------------------------------------------------------------
# This file is part of the rogue software platform. It is subject to
# the license terms in the LICENSE.txt file found in the top-level directory
# of this distribution and at:
#    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
# No part of the rogue software platform, including this file, may be
# copied, modified, propagated, or distributed except according to the terms
# contained in the LICENSE.txt file.
#-----------------------------------------------------------------------------
import pyrogue as pr
import ucsc_hn_lib
import numpy as np
import time

class RenaDataEmulator(pr.Device):

    def __init__(self, *, dataFile, **kwargs ):
        pr.Device.__init__(self, **kwargs)

        self._processor = ucsc_hn_lib.RenaDataEmulator(dataFile)

        self.add(pr.LocalVariable(name='DataEnable', description='Data Enable',
                                  mode='RW', value=False,
                                  localSet=lambda value: self._processor.setDataEnable(value),
                                  localGet=lambda : self._processor.getDataEnable()))

        self.add(pr.LocalVariable(name='BurstSize', description='BurstSize',
                                  mode='RW',
                                  localSet=lambda value: self._processor.setBurstSize(value),
                                  localGet=lambda : self._processor.getBurstSize()))


        self.add(pr.LocalVariable(name='FrameCount', description='Frame Count',
                                  mode='RO', value=0, pollInterval=1,
                                  localGet=lambda : self._processor.getCount()))

    def _start(self):
        self._processor._start()

    def _stop(self):
        self._processor._stop()

    def _getStreamMaster(self):
        return self._processor

    def __rshift__(self,other):
        pyrogue.streamConnect(self,other)
        return other

    def countReset(self):
        self._processor.countReset()

