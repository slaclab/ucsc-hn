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
import time

class DataDecoder(pr.Device):

    def __init__(self, *, nodeId=0, **kwargs ):
        pr.Device.__init__(self, **kwargs)

        self._processor = ucsc_hn_lib.RenaDataDecoder(nodeId)

        self.add(pr.LocalVariable(name='FrameCount', description='Frame Count',
                                  mode='RO', value=0, pollInterval=1,
                                  localGet=lambda : self._getFrameCount()))

        self.add(pr.LocalVariable(name='FrameRate', description='Frame Rate',
                                  mode='RO', value=0.0, disp='{:.1f}'))

        self.add(pr.LocalVariable(name='ByteCount', description='Byte Count',
                                  mode='RO', value=0, pollInterval=1,
                                  localGet=lambda : self._getByteCount()))

        self.add(pr.LocalVariable(name='ByteRate', description='Byte Rate',
                                  mode='RO', value=0.0, disp='{:.1f}'))

        self.add(pr.LocalVariable(name='SampleCount', description='Sample Count',
                                  mode='RO', value=0, pollInterval=1,
                                  localGet=lambda : self._getSampleCount()))

        self.add(pr.LocalVariable(name='SampleRate', description='Sample Rate',
                                  mode='RO', value=0.0, disp='{:.1f}'))

        self.add(pr.LocalVariable(name='DropCount', description='Drop Count',
                                  mode='RO', value=0, pollInterval=1,
                                  localGet=lambda : self._getDropCount()))

        self.add(pr.LocalVariable(name='DropRate', description='Drop Rate',
                                  mode='RO', value=0, disp='{:.1f}'))

        self._lastFrameCount = 0
        self._lastFrameTime = time.time()
        self._lastByteCount = 0
        self._lastByteTime = time.time()
        self._lastSampleCount = 0
        self._lastSampleTime = time.time()
        self._lastDropCount = 0
        self._lastDropTime = time.time()

    def countReset(self):
        self._processor.countReset()
        super().countReset()

    def _getStreamSlave(self):
        return self._processor

    def _getStreamMaster(self):
        return self._processor

    def __lshift__(self,other):
        pyrogue.streamConnect(other,self)
        return other

    def __rshift__(self,other):
        pyrogue.streamConnect(self,other)
        return other

    def __eq__(self,other):
        pyrogue.streamConnectBiDir(other,self)

    def _getFrameCount(self):
        curr = self._processor.getRxFrameCount()
        rate = (curr - self._lastFrameCount) / (time.time() - self._lastFrameTime)
        self._lastFrameCount = curr
        self._lastFrameTime  = time.time()
        self.FrameRate.set(rate)
        return curr

    def _getByteCount(self):
        curr = self._processor.getRxByteCount()
        rate = (curr - self._lastByteCount) / (time.time() - self._lastByteTime)
        self._lastByteCount = curr
        self._lastByteTime  = time.time()
        self.ByteRate.set(rate)
        return curr

    def _getDropCount(self):
        curr = self._processor.getRxDropCount()
        rate = (curr - self._lastDropCount) / (time.time() - self._lastDropTime)
        self._lastDropCount = curr
        self._lastDropTime  = time.time()
        self.DropRate.set(rate)
        return curr

    def _getSampleCount(self):
        curr = self._processor.getRxSampleCount()
        rate = (curr - self._lastSampleCount) / (time.time() - self._lastSampleTime)
        self._lastSampleCount = curr
        self._lastSampleTime  = time.time()
        self.SampleRate.set(rate)
        return curr

