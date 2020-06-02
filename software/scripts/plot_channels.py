
import numpy as np
import time
import matplotlib.pyplot as plt
import matplotlib.backends.backend_pdf
import sys

if len(sys.argv) != 2:
    print(f"Usage: {sys.argv[0]} data_file.dat")
    sys.exit()

inFile = sys.argv[1]
outFile = sys.argv[1] + ".pdf"

plots = {}

# Init Data
for node in range(1):
    if node not in plots:
        plots[node] = {}

    for board in range(7,10):
        if board not in plots[node]:
            plots[node][board] = {}

        for rena in range(2):
            if rena not in plots[node][board]:
                plots[node][board][rena] = {}

            for channel in range(36):
                if channel not in plots[node][board][rena]:
                    plots[node][board][rena][channel] = {'pha' : [], 'pol': 0, 'uVal' : [], 'vVal' : [], 'plt' : None}

print(f"Opening {sys.argv[1]}.")
print("Reading data......")
ct = time.time()
count = 0

with open(inFile) as f:
    for line in f:
        data = line.rstrip().split(' ')

        node   = int(data[0])
        board  = int(data[1])
        rena   = int(data[2])
        chan   = int(data[3])
        pol    = int(data[4])
        pha    = int(data[5])
        uVal   = int(data[6])
        vVal   = int(data[7])
        tstamp = int(data[8])

        plots[node][board][rena][chan]['pol']  = pol
        plots[node][board][rena][chan]['vVal'].append(vVal)
        plots[node][board][rena][chan]['uVal'].append(uVal)
        plots[node][board][rena][chan]['pha'].append(pha)

        if int(ct) != int(time.time()):
            print(f"Read {count} entries")
            ct = time.time()

        count += 1

print("Done reading data")
print("Generating plots....")

pdf = matplotlib.backends.backend_pdf.PdfPages(outFile)
figs = plt.figure()

for node in range(1):
    for board in range(7,10):
        for rena in range(2):

            for page in range(9):
                fig = plt.figure(figsize=(8.5,11))

                for sc in range(4):
                    channel = page*4 + sc

                    plt.subplot(2, 2, sc+1)

                    _ = plt.hist(plots[node][board][rena][channel]['pha'],bins='auto')
                    pol = plots[node][board][rena][channel]['pol']
                    plt.title(f"N{node}, B{board}, R{rena}, C{channel}, P{pol}")

                pdf.savefig(fig)

pdf.close()

print("Done Generating plots")

def plot(node, board, rena, channel):
    _ = plt.hist(plots[node][board][rena][channel]['pha'],bins='auto')
    plt.title("Histogram with 'auto' bins")
    plt.show()

