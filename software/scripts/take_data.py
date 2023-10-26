import pyrogue.interfaces
import time
import os
import datetime

import argparse
parser = argparse.ArgumentParser('Take Data Script')

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

parser.add_argument(
    "--mode",
    required = True,
    choices = ['test', 'normal'],
    help     = "Run Mode",
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

    # Figure out data, state and config names
    ts = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    data = args.output + "/data_" + ts + ".dat"
    state = args.output + "/state_" + ts + ".yml"
    conf = args.output + "/config_" + ts + ".yml"
    oldConf = args.output + "/config_" + ts + ".cfg"

    # First save config and legacy config
    client.MultiRenaRoot.SaveConfig(conf)
    client.MultiRenaRoot.SaveOldConfig(oldConf)

    # Open data file
    client.MultiRenaRoot.LegacyWriter.DataFile.set(data)
    client.MultiRenaRoot.LegacyWriter.Open()

    # Start Data Run
    client.MultiRenaRoot.RunControl.runRate.setDisp('Test Mode' if args.mode == 'test' else 'Normal Mode')
    client.MultiRenaRoot.RunControl.runState.setDisp("Running")

    # Take data for 30 seconds
    print("Taking data for 30 seconds")
    time.sleep(30)

    # Stop Run
    client.MultiRenaRoot.RunControl.runState.setDisp("Stopped")

    # Close Data file
    client.MultiRenaRoot.LegacyWriter.Close()

    # Save State
    client.MultiRenaRoot.SaveState(state)

