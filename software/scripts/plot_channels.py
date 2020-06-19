
import numpy as np
import time
import matplotlib.pyplot as plt
import matplotlib.backends.backend_pdf
import sys
from scipy.stats import norm
import pylab
if len(sys.argv) < 2:
    print(f"Usage: {sys.argv[0]} data_file.dat")
    sys.exit()

print(f"List: {sys.argv[1:]}")
summary = {}

# Init summary Data
for node in range(1):
    if node not in summary:
        summary[node] = {}

    for board in range(7,10):
        if board not in summary[node]:
            summary[node][board] = {}

        for rena in range(2):
            if rena not in summary[node][board]:
                summary[node][board][rena] = {}

            for channel in range(36):
                if channel not in summary[node][board][rena]:
                    summary[node][board][rena][channel] = {'pol': 0, 'hits': [], 'mean' : [], 'sigma' : []}

                    for _ in sys.argv[1:]:
                        summary[node][board][rena][channel]['hits'].append(0)
                        summary[node][board][rena][channel]['mean'].append(0)
                        summary[node][board][rena][channel]['sigma'].append(0)


for sumIdx,inFile in enumerate(sys.argv[1:]):
    outFile = inFile + ".pdf"
    print(f"Processing {inFile}")

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
                        plots[node][board][rena][channel] = {'pha' : [], 'pol': 0, 'uVal' : [], 'vVal' : []}

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
            if pha != 0:
                plots[node][board][rena][chan]['pha'].append(pha)

            if int(ct) != int(time.time()):
                print(f"Read {count} entries")
                ct = time.time()

            count += 1

    print("Done reading data")
    print("Generating plots....")

    pdf = matplotlib.backends.backend_pdf.PdfPages(outFile)
    figs = plt.figure()
    fig = None
    idx = 0

    for node in range(1):
        for board in range(7,10):
            for rena in range(2):
                for channel in range(36):

                    # Only plot channels with data
                    if len(plots[node][board][rena][channel]['pha']) != 0:
                        pol = plots[node][board][rena][channel]['pol']
                        summary[node][board][rena][channel]['pol'] = pol

                        pha_path = plots[node][board][rena][channel]['pha']
                        mean_sigma = norm.fit(pha_path)
                        #print(f"N{node}, B{board}, R{rena}, C{channel}, P{pol} = {mean_sigma} id={id(pha_path)}")
                        # Fit histogram here

                        summary[node][board][rena][channel]['hits'][sumIdx] = len(plots[node][board][rena][channel]['pha'])
                        summary[node][board][rena][channel]['mean'][sumIdx] = mean_sigma[0]
                        summary[node][board][rena][channel]['sigma'][sumIdx] = mean_sigma[1]

                        # Start of a new page
                        if (idx % 4) == 0:
                            fig = plt.figure(figsize=(8.5,11))

                        plt.subplot(2, 2, (idx%4)+1)

                        _ = plt.hist(plots[node][board][rena][channel]['pha'],bins='auto')
                        plt.title(f"N{node}, B{board}, R{rena}, C{channel}, P{pol}")

                        # Last plot of a page
                        if (idx % 4) == 3:
                            pdf.savefig(fig)
                            fig = None

                        idx += 1

    if fig is not None:
        pdf.savefig(fig)

    pdf.close()

    print("Done Generating plots")

# Save summary data
with open("summary.csv","w") as f:
    print("Creating Summary File")

    f.write("node,board,rena,channel,pol")

    for inFile in sys.argv[1:]:
        f.write(f",{inFile} Hits, {inFile} Mean, {inFile} Sigma")

    f.write("\n");

    # Init summary Data
    for node in range(1):
        for board in range(7,10):
            for rena in range(2):
                for channel in range(36):
                    pol = summary[node][board][rena][channel]['pol']

                    f.write(f"{node},{board},{rena},{channel},{pol}")

                    for inIdx,inFile in enumerate(sys.argv[1:]):
                        f.write(f",{summary[node][board][rena][channel]['hits'][inIdx]}")
                        f.write(f",{summary[node][board][rena][channel]['mean'][inIdx]:.2f}")
                        f.write(f",{summary[node][board][rena][channel]['sigma'][inIdx]:.2f}")

                    f.write("\n");

    print("Done")
