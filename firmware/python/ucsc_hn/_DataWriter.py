
import threading
import pyrogue as pr
import crc8

class DataWriter(pr.DataWriter):

    def __init__(self, *, hidden=True, **kwargs):
        """Initialize device class"""

        pr.DataWriter.__init__(self, hidden=hidden, **kwargs)

        self._lock = threading.Lock()
        self._file = None
        self._triggerCount = 0

    def _open(self):
        with self._lock:
            self._file = open(self.DataFile.value(),'a')
            self._triggerCount = 0
        self.IsOpen.get()

    def _close(self):
        with self._lock:
            if self._file is not None:
                self._file.close()
                self._file = None
        self.IsOpen.get()

    def _isOpen(self):
        with self._lock:
            return self._file is not None

    def _getCurrentSize(self):
        with self._lock:
            if self._file is not None:
                return self._file.tell()
            else:
                return 0

    def _getTotalSize(self):
        with self._lock:
            if self._file is not None:
                return self._file.tell()
            else:
                return 0

    def _getFrameCount(self):
        return self._triggerCount

    def _writeDataPacket(self, records):

        with self._lock:

            if self._file is None:
                return

            self._triggerCount += 1

            for rec in records:
                msg = f"{rec['nodeId']} {rec['fpgaId']} {rec['renaId']} {rec['channel']} {rec['polarity']} {rec['PHA']} {rec['U']} {rec['V']} {rec['timeStamp']}\n"
                self._file.write(msg)


