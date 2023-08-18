
import sys

NodeList = [i for i in range(10)]
FpgaList = [i for i in range(15,31)]

KeyList = [f'{node}-{fpga}' for node in NodeList for fpga in FpgaList]

hitList = {}

if len(sys.argv) != 3:
    print("Usage: cts_analyze.py rena_file.dat output")
    sys.exit(1)

# First get a baseline of timestamps

filtNode = 5
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

