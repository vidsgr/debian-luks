REQUIREMENTS
------------
The following recipes have been tested on Debian Stretch: on other Debian versions your mileage might vary. Debos is a very promising but still young project; its support for Ubuntu is in the works but not yet ready.

Since Debos uses a virtualization technology (via fakemachine) to isolate itself from the underlying OS, running these recipes inside a VM requires special care.

Basically you have two choices:
- enabling nested VM support in your virtualizer;
- launching the debos commands as root with sudo.

Nested virtualization support will be slower, but maintains the build process well isolated from your system. The sudo way, on the other hand, while being faster might expose you to potentially dangerous bugs. If you follow that route, you'd better make sure that your VM serve *only* for the task at hand.

INSTALL
-------

Install prerequisites:

```
sudo apt install golang git libglib2.0-dev libostree-dev qemu-system-x86 \
     qemu-user-static debootstrap systemd-container grub-pc-bin cryptsetup
sudo systemctl start systemd-resolved
GOPATH=`pwd`/gocode go get -u github.com/go-debos/debos/cmd/debos
```

USAGE
-----

The command

```
./gocode/bin/debos debootstrap.yaml
```

produces a tar.gz archive with a debostrapped Debian root filesystem. By default, it's Debian Stable for amd64 architecture, but there are a few configurable parameters. For instance, to create an archive for architecture i686 and targeting testing you would do:

```
./gocode/bin/debos -t arch:i686 -t suite:testing debootstrap.yaml
```

Look at the first lines of debian.yaml to see what's available.

The archive produced can be used as a drop-in replacement for the rootfs created by deboostrap, but debos system to produce it is more powerful without adding to much complexity to the build - all you need to do is modify debian.yaml (see [1] and [2] for documentation).

Also, the directory

```
overlays/customization/
```

is rsync'd to the root of the new filesystem - if you need to add your own stuff.

The archive generated can be converted to a bootable image using the following command:

```
./gocode/bin/debos luks.yaml
```

which will generate a 4G img file, along with a secrets.txt (if one is already present, it will be used) which is the LUKS encryption password for the root filesystem.

CACHING
-------

Downloading deb packages over and over is time consuming. You can setup a local cache and
use it as a proxy, like this:

```
sudo apt install apt-cacher-ng
export http_proxy=http://<your LAN IP here>:3142
```

Subsequent builds will reuse local packages. Note that you really need to use your LAN IP,
localhost will not work. Also, be aware that apt-cacher-ng will be accessible from outside
your machine unless you firewall it.

LINKS
-----

[1] https://ekaia.org/blog/2018/07/03/introducing-debos/
[2] https://godoc.org/github.com/go-debos/debos/actions
