
# Anaconda Quick-start

The following is how you install the latest released version of this software with anaconda.

```

   $ conda create -n ucsc_hn -c tidair-tag -c conda-forge multirena


```

You will need to install the crc8 package manually using pip:


```

   $ conda activate ucsc_hn
   $ pip3 install crc8

```

To run the software:

```

   $ conda activate ucsc_hn
   $ renaGui --host=ip1 --host=ip2

```

To update the multirena package

```

   $ conda activate ucsc_hn
   $ conda update multirena -c tidair-tag -c conda-forge

```
