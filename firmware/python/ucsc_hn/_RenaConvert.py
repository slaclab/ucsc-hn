import pyrogue
import crc8
import os

class RenaConvert(pyrogue.Process):
    def __init__(self, **kwargs):
        pyrogue.Process.__init__(self, description="Rena Dava Converter.", **kwargs)

        self.add(pyrogue.LocalVariable(
            name = 'InputFile',
            mode = 'RW',
            value = "",
            description = "Input file for data conversion"))

        self.add(pyrogue.LocalVariable(
            name = 'OutputFile',
            mode = 'RW',
            value = "",
            description = "Output file for data conversion"))

        self.add(pyrogue.LocalVariable(
            name = 'TotalRecords',
            pollInterval=1.0,
            mode = 'RO',
            value = 0,
            description = "Total number of records"))

        self.add(pyrogue.LocalVariable(
            name = 'ErroredRecords',
            pollInterval=1.0,
            mode = 'RO',
            value = 0,
            description = "Total number of errored records"))

        self.add(pyrogue.LocalVariable(
            name = 'GoodRecords',
            pollInterval=1.0,
            mode = 'RO',
            value = 0,
            description = "Total number of good records"))

        self.Step.setPollInterval(1.0)

        @self.command()
        def AutoSetFile():
            ifile = self.root.LegacyWriter.DataFile.value()
            ofile = ifile.replace('.dat','.txt')
            self.InputFile.set(ifile)
            self.OutputFile.set(ofile)

    def _process(self):
        self.Message.setDisp("Running")
        self.Progress.set(0.0)
        self.TotalRecords.set(0)
        self.ErroredRecords.set(0)
        self.GoodRecords.set(0)
        data = bytearray(1000)
        dataSize = 0
        readBytes = 0

        # Get file status
        stats = os.stat(self.InputFile.value())

        self.TotalSteps.set(stats.st_size)
        self.Step.set(0)

        # Open file, get size
        with open(self.InputFile.value(),'rb') as srcFile:
            with open(self.OutputFile.value(),'w') as dstFile:

                while readBytes < stats.st_size and self._runEn:

                    # Read until we find a marker
                    while readBytes < stats.st_size:
                        data[0] = srcFile.read(1)[0]
                        readBytes += 1
                        if data[0] == 0xc8 or data[0] == 0xc9:
                            break
                    dataSize = 1

                    # get source Id, skip dest ID
                    if readBytes < stats.st_size:
                        nodeId = int(srcFile.read(1)[0])
                        srcFile.read(1)
                        readBytes += 2

                    # Read until we find the end marker
                    while readBytes < stats.st_size:
                        data[dataSize] = srcFile.read(1)[0]
                        readBytes += 1
                        dataSize += 1
                        if data[dataSize-1] == 0xFF:
                            break

                    ####################### Process Frame ##############################

                    # Compute CRC
                    if dataSize > 4:
                        hash = crc8.crc8()
                        hash.update(data[0:dataSize-3])
                        crc = data[dataSize-3] << 4 | data[dataSize-2]
                        good = (crc == hash.digest()[0])

                    self.TotalRecords.set(self.TotalRecords.value() + 1,write=False)

                    # Compare CRC
                    if not good:
                        self.ErroredRecords.set(self.ErroredRecords.value()+1,write=False)
                        continue

                    # Bytes 2 - 7 are the timesamp, 42 bits total
                    timeStamp = 0;
                    for x in range(2,8):
                        timeStamp = timeStamp << 7
                        timeStamp |= data[x]

                    # Bytes 8 - 13 are the fast trigger list for channels 35-0
                    fastTriggerList = 0;
                    for x in range(8,14):
                        fastTriggerList = fastTriggerList << 6
                        fastTriggerList |= data[x]

                    buffIdx = 14

                    # Bytes 14 - 19 are the slow trigger list for channels 35-0
                    slowTriggerList = 0

                    # OR Mode
                    if data[0] == 0xc9:
                        for x in range(14,20):
                            slowTriggerList = slowTriggerList << 6;
                            slowTriggerList |= data[x]

                        buffIdx = 20

                    # Count the number of fast triggers
                    fastCount = 0
                    i = 1
                    for x in range(0, 36):
                        if (i & fastTriggerList) != 0:
                            fastCount += 1
                        i = i << 1

                    # Count the number of slow triggers
                    slowCount = 0

                    # OR Mode
                    if data[0] == 0xc9:
                       i = 1
                       for x in range(0, 36):
                           if ((i & slowTriggerList) != 0 ):
                               slowCount += 1
                           i = i << 1

                       # Check or mode length
                       if dataSize != (23 + (fastCount * 4) + (slowCount * 2)):
                            self.ErroredRecords.set(self.ErroredRecords.value()+1,write=False)
                            continue

                    # Check and mode length
                    elif dataSize != (17 + (fastCount * 6)):
                        self.ErroredRecords.set(self.ErroredRecords.value()+1,write=False)
                        continue;

                    # Good frame continue to process
                    self.GoodRecords.set(self.GoodRecords.value()+1,write=False)

                    # Gets IDs
                    renaId = data[1] & 0x1
                    fpgaId = data[1] >> 1 & 0x3F

                    # Extract data PHA, U and V ADC values for each channel
                    for x in range(0,36):
                        bit = 1 << x
                        readPHA = False
                        readUV  = False

                        # OR Mode
                        if data[0] == 0xc9:
                            readPHA = ((bit & slowTriggerList) != 0)
                            readUV  = ((bit & fastTriggerList) != 0)

                        # AND Mode
                        else:
                            if (bit & fastTriggerList) != 0:
                                readPHA = True
                                readUV  = True

                        # Something is being read for this channel
                        if readPHA or readUV:

                            # PHA is two bytes
                            if readPHA:
                                phaData = data[buffIdx] << 6 | data[buffIdx+1]
                                buffIdx += 2
                            else:
                                phaData = 0

                            # U & V Data
                            if readUV:
                                uData = data[buffIdx] << 6 | data[buffIdx+1]
                                vData = data[buffIdx+2] << 6 | data[buffIdx+3]
                                buffIdx += 4

                            else:
                                uData = 0
                                vData = 0

                            # Lookup polarity
                            polarity = self.root.Node[nodeId].RenaArray.RenaBoard[fpgaId].Rena[renaId].Channel[x].Polarity.value()

                            # Add file entry
                            print(f"{nodeId} {fpgaId} {renaId} {x} {polarity} {phaData} {uData} {vData} {timeStamp}", file=dstFile)

                    ####################### End Process Frame ##############################
                    #print("-------------------------------------",file=dstFile)

                    # Update status
                    self.Step.set(readBytes,write=False)
                    self.Progress.set(self.Step.value()/self.TotalSteps.value(),write=False)

        # Done
        self.Message.setDisp("Done")
        self.Progress.set(1.0)

