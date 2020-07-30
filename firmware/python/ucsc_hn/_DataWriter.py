
import threading
import crc8
import ucsc_hn_lib
import pyrogue.utilities.fileio

class DataWriter(pyrogue.utilities.fileio.StreamWriter):

    def __init__(self, *, hidden=True, **kwargs):
        """Initialize device class"""

        pyrogue.utilities.fileio.StreamWriter.__init__(self, hidden=hidden, **kwargs)

        self._writer = ucsc_hn_lib.RenaDataWriter()

