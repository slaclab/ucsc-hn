
# Get uboot from https://pypi.org/project/uboot/
import uboot

fname = "/mnt/uboot.env"
#fname = "/run/media/ryan/BOOT/uboot.env"
#fname = "/run/media/ryan/BOOT/uboot.env.working"

with open(fname,"rb") as f:
    env = uboot.EnvBlob.parse(f.read())
    env.size = 131072

env.set("ethaddr","08:00:56:00:54:37")

with open(fname,"wb") as f:
    f.write(env.export())

print(env)
