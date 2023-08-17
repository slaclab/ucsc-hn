
import yaml
import sys

if len(sys.argv) == 1:
    print("Usage: dump_stats.py dir_to/state_file.yml")
    sys.exit(1)

for file in sys.argv[1:]:
    name = file.split('/')[0] + '.txt'

    totalBytes = 0
    data = {}

    with open(file) as f:
        print(f"Processing {file} to {name}")
        strData = f.read()

        data = yaml.load(strData,Loader=yaml.Loader)

        with open(name,'w') as res:
            for i in range(10):

                key = f"Node[{i}]"

                if key in data['MultiRenaRoot']:

                    print(f"------------- {key} ----------------", file=res)

                    for k in ['RetransmitCnt', 'DropCnt']:
                        val = data['MultiRenaRoot'][key]['RssiCore'][k]
                        print(f"Rx {k} = {val}", file=res)

                    for fifo in ['TestFifo', 'DiagFifo', 'DataFifo', 'LegFifo']:

                        for k in ['FrameDropCnt']:
                            val = data['MultiRenaRoot'][key]['RenaArray'][fifo][k]
                            print(f"{fifo} {k} = {val}", file=res)

                    for k in ['rssiDropCount', 'rssiRetranCount']:
                        val = data['MultiRenaRoot'][key]['RenaArray']['UdpRssiPack'][k]
                        print(f"Tx {k} = {val}", file=res)

                    totalBytes += data['MultiRenaRoot'][key]['RenaArray']['DataDecoder']['ByteCount']

                    for k in ['FrameCount', 'ByteCount', 'SampleCount', 'DropCount', 'DecodeEn']:
                        val = data['MultiRenaRoot'][key]['RenaArray']['DataDecoder'][k]
                        print(f"Decode {k} = {val}", file=res)

#                    for i in range(1,31):
#                        for k in [f'RxCount[{i}]', f'RxTotal[{i}]']:
#                            val = data['MultiRenaRoot'][key]['RenaArray']['DataDecoder'][k]
#                            if val != 0:
#                                print(f"Decode {k} = {val}", file=res)

            print("", file=res)
            for wr in ['DataWriter', 'LegacyWriter']:
                for k in ['TotalSize', 'FrameCount']:
                    val = data['MultiRenaRoot'][wr][k]
                    print(f"{wr} {k} = {val}", file=res)

            print("", file=res)
            print(f"Total Bytes = {totalBytes}", file=res)

            bw = totalBytes / 30.0
            print(f"Bandwidth = {bw}", file=res)


