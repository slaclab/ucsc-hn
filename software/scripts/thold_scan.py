
#####################################
# Configuration
#####################################

# Threshold Steps for Cathod and Anonde. Both lists need to be the same length
AnodeDacValues = [65, 75, 85]
CathodeDacValues = [150, 145, 140]

# Time per step in seconds
TimePerStep = 30

#####################################
# Runtime Code Below
#####################################
import pyrogue.interfaces
import time
import os
import datetime
import argparse
parser = argparse.ArgumentParser('Threshold Scan')

parser.add_argument(
    "--config",
    required = True,
    help     = "Top Configuration File.",
)

parser.add_argument(
    "--output",
    required = True,
    help     = "Output Directory",
)

# Get the arguments
args = parser.parse_args()

# Create the data directory if it does not exist
if not os.path.exists(args.output):
    os.makedirs(args.output)

# First attempt to a running server
with pyrogue.interfaces.VirtualClient('localhost',9099) as client:

    # Cleanup State Of the System
    client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")
    client.MultiRenaRoot.DataWriter.Close()
    client.MultiRenaRoot.LegacyWriter.Close()

    # Hard reset the system
    client.MultiRenaRoot.HardReset()

    # Load the configuration
    client.MultiRenaRoot.LoadConfig(args.config)
    print("Load Config Done")

    # Initialize & count reset
    client.MultiRenaRoot.Initialize()
    client.MultiRenaRoot.CountReset()

    for aDac,cDac in zip(AnodeDacValues, CathodeDacValues):
        # Figure out data, state and config names
        ts = datetime.datetime.now().strftime(f"{aDac}_{cDac}_%Y%m%d_%H%M%S")
        data = args.output + "/data_" + ts + ".dat"
        state = args.output + "/state_" + ts + ".yml"
        conf = args.output + "/config_" + ts + ".yml"
        oldConf = args.output + "/config_" + ts + ".cfg"

        # Update all of the anode and cathode configurations
        for ni, node in client.MultiRenaRoot.Node.items():
            print(f"Setting Node {ni} Anode DAC values to {aDac}. Cathode DAC values to {cDac}.")
            for bi, board in node.RenaArray.RenaBoard.items():
                for ri, rena in board.Rena.items():
                    for ci, chan in rena.Channel.items():
                        if chan.Polarity.valueDisp() == 'Positive':
                            chan.FastDac.set(aDac)
                            chan.SlowDac.set(aDac)
                        else:
                            chan.FastDac.set(cDac)
                            chan.SlowDac.set(cDac)

            # Configure
            node.RenaArray.ConfigBoards()

        # Initialize and count reset
        client.MultiRenaRoot.Initialize()
        client.MultiRenaRoot.CountReset()

        # First save config and legacy config
        client.MultiRenaRoot.SaveConfig(conf)
        client.MultiRenaRoot.SaveOldConfig(oldConf)

        # Open data file
        client.MultiRenaRoot.LegacyWriter.DataFile.set(data)
        client.MultiRenaRoot.LegacyWriter.Open()

        # Start Data Run
        client.MultiRenaRoot.RunControl.runRate.setDisp('Test Mode')
        client.MultiRenaRoot.RunControl.runState.setDisp("Running")

        # Take data for 30 seconds
        print(f"Taking data for {TimePerStep} seconds")
        time.sleep(TimePerStep)

        # Stop Run
        client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")

        # Close Data file
        client.MultiRenaRoot.LegacyWriter.Close()

        # Save State
        client.MultiRenaRoot.SaveState(state)

