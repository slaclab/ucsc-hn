

import sys

if len(sys.argv) != 3:
    print("Usage: convert_data.py input_file.dat output_file.txt")
    sys.exit(1)

recCount = 0
chanCount = 0

with open(sys.argv[1],'rb') as fin:
    with open(sys.argv[2],'w') as fout:

        while (True):

            # read 16 bytes
            head = fin.read(16)

            if len(head) < 16:
                print(f"End of faile after {recCount} records, {chanCount} channels of data")
                sys.exit(0)

            fpgaId  = int.from_bytes(head[0:1], byteorder='little', signed=False)
            renaId  = int.from_bytes(head[1:2], byteorder='little', signed=False)
            nodeId  = int.from_bytes(head[2:3], byteorder='little', signed=False)
            tstamp  = int.from_bytes(head[3:11], byteorder='little', signed=False)
            frameId = int.from_bytes(head[11:15], byteorder='little', signed=False)
            count   = int.from_bytes(head[15:16], byteorder='little', signed=False)
            recCount += 1

            # Read each channel
            for _ in range(count):

                record = fin.read(8)

                if len(record) < 8:
                    print("Partial data error ! Reached End Of File")
                    sys.exit(1)

                chan = int.from_bytes(record[0:1], byteorder='little', signed=False)
                pol  = int.from_bytes(record[1:2], byteorder='little', signed=False)
                phaD = int.from_bytes(record[2:4], byteorder='little', signed=False)
                uD   = int.from_bytes(record[4:6], byteorder='little', signed=False)
                vD   = int.from_bytes(record[6:8], byteorder='little', signed=False)
                chanCount += 1

                # Record record
                print(f'{nodeId} {fpgaId} {renaId} {chan} {pol} {phaD} {uD} {vD} {tstamp}', file=fout)

            if recCount % 10000 == 0:
                print(f"Processed {recCount} records, {chanCount} channels of data")

