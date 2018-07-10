This tool tries to solve the "OpenGL" problem on nix. Works with Nvidia cards (with bumblebee) and most of the card supported by mesa (such as Intel, AMD and nouveau using the free driver). It works for Vulkan programs too.

# Quick start

Suppose you have a configuration with an nvidia card, host driver version `390.25`

```
# clone the repository
git clone https://github.com/guibou/nixGL
cd nixGL

# build and install the wrapper
./nvidiaInstall.py 390.25 nixGLNvidia

# install the wrapper
nix-env -i ./result

# use it with any OpenGL application
nixGLNvidia blender
```

# Motivation

You use Nix on any distribution, and any GL application installed fails with this error:

```
$ program
libGL error: unable to load driver: i965_dri.so
libGL error: driver pointer missing
libGL error: failed to load driver: i965
libGL error: unable to load driver: i965_dri.so
libGL error: driver pointer missing
libGL error: failed to load driver: i965
libGL error: unable to load driver: swrast_dri.so
libGL error: failed to load driver: swrast
```

This library contains a wrapper which is able to launch GL or Vulkan applications:

```
nixGLXXX program
nixVulkanXXX program
```

# Installation / Usage

Clone this git repository:

```
git clone https://github.com/guibou/nixGL
cd nixGL
```

## Optional (if NVIDIA): Grab your NVIDIA driver version

Using `glxinfo` from your host system, grab the driver version, here `390.25`:

```
$ glxinfo | grep NVIDIA
...
OpenGL core profile version string: 4.5.0 NVIDIA 390.25
...
```

## Build

### For mesa (intel, amd, nouveau, ...)

For mesa (intel, amd, nouveau) GL, the package is historically called `nixGLIntel`:

```
nix-build -A nixGLIntel
```

For Intel Vulkan:

```
nix-build -A nixVulkanIntel
```

### For nvidia

Due to some restriction on `nix` 2.0, the `nix-build` must be called with a wrapper script.

For NVIDIA GL alone:

```
./nvidiaInstall.py 390.25 nixGLNvidia
```

For NVIDIA Vulkan alone:

Note that the NVIDIA GL and Vulkan wrappers are identical aside from the name

```
./nvidiaInstall.py 390.25 nixVulkanNvidia
```

(replace `390.25` with the host driver version gathered earlier.)

For Nvidia with bumblebee:

```
./nvidiaInstall.py 390.25 nixGLNvidiaBumblebee
```

(replace `390.25` with the host driver version gathered earlier.)

## Install

The previous commands only build the wrapper, now stored inside `./result`, you need to install it:

```
nix-env -i ./result
```

(Note, you can iterate many time on this process to install as many driver as needed. Common example are `nixGLIntel` with `nixGLNvidiaBumblebee`)


# Usage

For GL programs

```
nixGLXXX program args
```

For Vulkan programs

```
nixVulkanXXX program args
```

For example (on my dual GPU laptop):

```bash
$ nixGLIntel glxinfo | grep -i 'OpenGL version string'
OpenGL version string: 3.0 Mesa 17.3.3
$ nixGLNvidiaBumblebee glxinfo | grep -i 'OpenGL version string'
OpenGL version string: 4.6.0 NVIDIA 390.25
```

Another example (on an XPS 9560 with the Intel GPU selected):

```bash
$ sudo apt install mesa-vulkan-drivers
...
$ nixVulkanIntel $(nix-build '<nixpkgs>' --no-out-link -A vulkan-loader)/bin/vulkaninfo | grep VkPhysicalDeviceProperties -A 7
VkPhysicalDeviceProperties:
===========================
        apiVersion     = 0x400036  (1.0.54)
        driverVersion  = 71311368 (0x4402008)
        vendorID       = 0x8086
        deviceID       = 0x591b
        deviceType     = INTEGRATED_GPU
        deviceName     = Intel(R) HD Graphics 630 (Kaby Lake GT2)
```

# Limitations

Does not work now for AMD drivers because I dont' have the hardware.

# Comparaison with similar tools

[nix-install-vendor-gl.sh](https://github.com/deepfire/nix-install-vendor-gl)
provides a similar system with a different approach:

- it auto detect the host driver
- it needs root access and set your system for a specific driver
- it only provides wrappers for nvidia (without bumblebee)

Both projects are now really similar and the only reason I did not
contributed to `nix-install-vendor-gl.sh` was because initial `nixGL`
had a totally different approach.

# Troubleshooting

If by any chance it does not work, you need to install nixGL using the same nixpkgs checkout than the one of your application. For example:

```bash
NIX_PATH=nixpkgs=https://github.com/nixos/nixpkgs/archive/94d80eb72474bf8243b841058ce45eac2b163943.tar.gz nix build -f ./default.nix nixGLIntel
```

# Old nvidia drivers

Users of nvidia legacy driver should use the `backport/noGLVND` branch.

# `nixGLCommon`

`nixGLCommon nixGLXXX` can be used to get `nixGL` executable which fallsback to `nixGLXXX`. It is a shorter name for people with only one OpenGL configuration.

For example:

```
nix-build -E "with import ./default.nix {}; nixGLCommon nixGLIntel"
