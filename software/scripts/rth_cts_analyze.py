
import sys
import numpy as np
import collections

#NodeList = [i for i in range(1,3)]
#FpgaList = [i for i in range(5,7)]

NodeList = [i for i in range(1,3)]
FpgaList = [i for i in range(20,21)]

KeyList = [f'{node}-{fpga}' for node in NodeList for fpga in FpgaList]

hitList = {}
deltaList = {}

if len(sys.argv) != 3 and len(sys.argv) != 4:
    print("Usage: cts_analyze.py rena_file.dat output [metrics]")
    sys.exit(1)

# First get a baseline of timestamps

filtNode = 1
filtFpga = 20
lastT = 0
totalKept = 0

print(f"Finding key timestamps using Node {filtNode} Fpga {filtFpga}")
with open(sys.argv[1]) as f:
    for line in f:
        fields = line.strip().split(' ')

        node = int(fields[0])
        fpga = int(fields[1])
        rena = int(fields[2])
        chan = int(fields[3])
        ts   = int(fields[8])

        # round ts
        tsr = (ts // 100) * 100

        if node == filtNode and fpga == filtFpga:
            if tsr not in hitList:
                hitList[tsr] = {key: 0 for key in KeyList}
                hitList[tsr]['orig'] = ts
                hitList[tsr]['delta'] = ts - lastT
                lastT = ts

print(f"Found {len(hitList)} timestamps")

print("Finding matching timestamps")
# Next attempt to match other channels to this timestamp
with open(sys.argv[1]) as f:
    for line in f:
        fields = line.strip().split(' ')

        node = int(fields[0])
        fpga = int(fields[1])
        rena = int(fields[2])
        chan = int(fields[3])
        ts   = int(fields[8])

        # round ts
        tsr = (ts // 100) * 100

        if tsr in hitList:
            hitList[tsr][f'{node}-{fpga}'] += 1
            k = f'{node}-{fpga}-{rena}-{chan}'

            if k not in deltaList:
                deltaList[k] = []

            deltaList[k].append(ts - hitList[tsr]['orig'])

print("Done.")
print("Writing Results")
totals = {key: 0 for key in KeyList}

with open(sys.argv[2], 'w') as of:

    st = "Ts\tOrig\tDelta\t"
    for key in KeyList:
        st += f"{key}\t"

    print(st, file=of)

    for k,v in hitList.items():
        st = f"{k}\t{v['orig']}\t{v['delta']}\t"

        for key in KeyList:
            st += f"{v[key]}\t"

            if v[key] != 0 and v['delta'] < 25100 and v['delta'] > 24900:
                totals[key] += 1

        print(st, file=of)

    st = f"Totals\t\t\t"
    for k,v in totals.items():
        st += f"{v}\t"

    print(st, file=of)

print("Done.")

if len(sys.argv) > 3:

    deltaList = collections.OrderedDict(sorted(deltaList.items()))

    print("Writing Diffs")
    with open(sys.argv[3], 'w') as of:

        st = "Chan\tMean\tDev\tMin\tMax\tLen"
        print(st, file=of)

        for k,v in deltaList.items():
            mean = np.mean(deltaList[k])
            std = np.std(deltaList[k])
            mn = np.min(deltaList[k])
            mx = np.max(deltaList[k])
            ln = len(deltaList[k])
            st = f"{k}\t{mean}\t{std}\t{mn}\t{mx}\t{ln}"
            print(st, file=of)

    print("Done.")

