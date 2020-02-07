import pyrogue
import rogue.hardware.axi
import rogue.interfaces.memory

import socket
import ipaddress
import time

class ZynqTcpServer(object):

    def __init__(self):

        print('Starting TcpServer')

        self.memMap = rogue.hardware.axi.AxiMemMap('/dev/rce_memmap')

        # Memory server on port 9000        
        self.memServer = rogue.interfaces.memory.TcpServer('*', 9000)
        pyrogue.busConnect(self.memServer, self.memMap)
        print(f'Opened Memory TcpServer on port {hps.constants.RCE_MEM_MAP_PORT}')


if __name__ == '__main__':

    server = ZynqTcpServer()

    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        print('Stopping TcpServer')

