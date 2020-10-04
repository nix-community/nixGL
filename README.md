# NixGL

NixGL solve the "OpenGL" problem with [nix](https://nixos.org/nix/). Works all mesa
drivers (intel cards and "free" version fro Nvidia or AMD cards), Nvidia
proprietary drivers, even with hybrid configuration (with bumblebee). It works
for Vulkan programs too.

# Motivation

You use Nix on any distribution, and any GL application installed fails with this error:

```bash
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

NixGL provides a set of wrappers able to launch GL or Vulkan applications:

```bash
$ nixGLXXX program
$ nixVulkanXXX program
```

# Installation

Clone this git repository:

```bash
$ git clone https://github.com/guibou/nixGL
$ cd nixGL
```

Many wrappers are available, depending on your hardware and the graphical API
you want to use (i.e. Vulkan or OpenGL). You may want to install a few of them,
for example if you want to support OpenGL and Vulkan on a laptop with an hybrid
configuration.

## OpenGL wrappers

- `nix-env -f ./ -iA nixGLIntel`: Mesa OpenGL implementation (intel, amd, nouveau, ...).
- `nix-env -f ./ -iA nixGLNvidiaBumblebee`: Proprietary Nvidia driver on hybrid hardware.
- `nix-env -f ./ -iA nixGLNvidia`: Proprietary Nvidia driver.
- `nix-env -f ./ -iA nixGLDefault`: Tries to auto-detect and install Nvidia,
    if not, fallback to mesa.

## Vulkan wrappers

- `nix-env -f ./ -iA nixVulkanNvidia`: Proprietary Nvidia driver.
- `nix-env -f ./ -iA nixVulkanIntel`: Mesa Vulkan implementation.

The Vulkan wrapper also sets `VK_LAYER_PATH` the validation layers in the nix store.

# Usage

Just launch the program you want prefixed by the right wrapped.

For OpenGL programs:

```bash
$ nixGLXXX program args
```

For Vulkan programs:

```bash
$ nixVulkanXXX program args
```

Replace `XXX` by the implementation pour previously selected, such as `nixGLIntel` or `nixGLNvidia`.

## Examples

# OpenGL - Hybrid Intel + Nvidia laptop

After installing `nixGLIntel` and `nixGLNvidiaBumblebee`.

```bash
$ nixGLIntel $(nix run nixpkgs.glxinfo -c glxinfo) | grep -i 'OpenGL version string'
OpenGL version string: 3.0 Mesa 17.3.3
$ nixGLNvidiaBumblebee $(nix run nixpkgs.glxinfo -c glxinfo) | grep -i 'OpenGL version string'
OpenGL version string: 4.6.0 NVIDIA 390.25
```

If the program you'd like to run is already installed by nix in your current environment, you can simply run it with the wrapper, for example:

```bash
$ nixGLIntel blender
```

# Vulkan - Intel GPU

After installing `nixVulkanIntel`.

```bash
$ sudo apt install mesa-vulkan-drivers
...
$ nixVulkanIntel $(nix-build '<nixpkgs>' --no-out-link -A vulkan-tools)/bin/vulkaninfo | grep VkPhysicalDeviceProperties -A 7
VkPhysicalDeviceProperties:
===========================
        apiVersion     = 0x400036  (1.0.54)
        driverVersion  = 71311368 (0x4402008)
        vendorID       = 0x8086
        deviceID       = 0x591b
        deviceType     = INTEGRATED_GPU
        deviceName     = Intel(R) HD Graphics 630 (Kaby Lake GT2)
```

# Troubleshooting

## Nvidia auto detection does not work

```bash
building '/nix/store/ijs5h6h07faai0k74diiy5b2xlxh891g-auto-detect-nvidia.drv'...
pcregrep: Failed to open /proc/driver/nvidia/version: No such file or directory
builder for '/nix/store/ijs5h6h07faai0k74diiy5b2xlxh891g-auto-detect-nvidia.drv' failed with exit code 2
error: build of '/nix/store/ijs5h6h07faai0k74diiy5b2xlxh891g-auto-detect-nvidia.drv' faile
```

You can run the Nvidia installer using an explicit version string instead of the automatic detection method:

```bash
nix-build -A nixGLNvidia --argstr nvidiaVersion 440.82
```

The version of your driver can be found using `glxinfo` from your system default package manager, or `nvidia-settings`.

## On nixOS

`nixGL` can also be used on nixOS if the system is installed with a different
nixpkgs clone than the one your application are installed with. Override the
`pkgs` argument of the script with the correct nixpkgs clone:

```bash
nix-build ./default.nix -A nixGLIntel --arg pkgs "import path_to_your_nixpkgs {}".
```

## Old nvidia drivers

Users of Nvidia legacy driver should use the `backport/noGLVND` branch. This branch is not tested and may not work well, please open a bug report, it will be taken care of as soon as possible.

# `nixGLCommon`

`nixGLCommon nixGLXXX` can be used to get `nixGL` executable which fallsback to `nixGLXXX`. It is a shorter name for people with only one OpenGL configuration.

For example:

```
nix-build -E "with import ./default.nix {}; nixGLCommon nixGLIntel"
```

# Using nixGL in your project




# Limitations

`nixGL` is badly tested, mostly because it is difficult to test automatically in a continuous integration context because you need access to different type of hardware.

Some OpenGL configurations may not work, for example AMD proprietary drivers. There is no fundamental limitation, so if you want support for theses configurations, open an issue.

# Hacking

One great way to contribute to nixGL is to run the test suite. Just run
`./Test.hs` in the main directory and check that all the test relevant to your
hardware are green.
