# NixGL

NixGL solve the "OpenGL" problem with [nix](https://nixos.org/nix/). It works with all mesa drivers (Intel cards and "free" version for Nvidia or AMD cards), Nvidia proprietary drivers, and even with hybrid configuration via bumblebee. It works for Vulkan programs too.

# Motivation

Using Nix on non-NixOS distros, it's common to see GL application errors:

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
$ nixGL program
$ nixVulkan program
```

# Installation

## nix-channel (Recommended)

To get started,

```bash
$ nix-channel --add https://github.com/guibou/nixGL/archive/main.tar.gz nixgl && nix-channel --update
$ nix-env -iA nixgl.auto.nixGLDefault   # or replace `nixGLDefault` with your desired wrapper
```

Many wrappers are available, depending on your hardware and the graphical API you want to use (i.e. Vulkan or OpenGL). You may want to install a few of them, for example if you want to support OpenGL and Vulkan on a laptop with an hybrid configuration.

OpenGL wrappers:

- `auto.nixGLDefault`: Tries to auto-detect and install Nvidia, if not, fallback to mesa. Recommended. Invoke with `nixGL program`.
- `auto.nixGLNvidia`: Proprietary Nvidia driver (auto detection of version)
- `auto.nixGLNvidiaBumblebee`: Proprietary Nvidia driver on hybrid hardware (auto detection).
- `nixGLIntel`: Mesa OpenGL implementation (intel, amd, nouveau, ...).

Vulkan wrappers:

- `auto.nixVulkanNvidia`: Proprietary Nvidia driver (auto detection).
- `nixVulkanIntel`: Mesa Vulkan implementation.

The Vulkan wrapper also sets `VK_LAYER_PATH` the validation layers in the nix store.

## Flakes

### Directly run nixGL

You need to specify the same version of `nixpkgs` that your `program` is using. For example, replace `nixos-21.11` with `nixos-21.05`.

```sh
nix run --override-input nixpkgs nixpkgs/nixos-21.11 --impure github:guibou/nixGL -- program
```

If you use the default `nixpkgs` channel (i.e. `nixpkgs-unstable`), you can ommit those arguments like so:

```sh
nix run --impure github:guibou/nixGL -- program
```

You can also specify which wrapper to use instead of using the default auto detection:

```sh
nix run github:guibou/nixGL#nixGLIntel -- program
```

This will result in a lighter download and execution time. Also, this evaluation is pure.


#### Error about experimental features

You can directly use:

```sh
nix --extra-experimental-features "nix-command flakes" run --impure github:guibou/nixGL -- program
```

Or set the appropriate conf in `~/.config/nix/nix.conf` / `/etc/nix/nix.conf` / `nix.extraOptions`.

#### Error with GLIBC version

if you get errors with messages similar to
```
/nix/store/g02b1lpbddhymmcjb923kf0l7s9nww58-glibc-2.33-123/lib/libc.so.6: version `GLIBC_2.34' not found (required by /nix/store/hrl51nkr7dszlwcs29wmyxq0jsqlaszn-libglvnd-1.4.0/lib/libGLX.so.0)
```

It means that there's a mismatch between the versions of `nixpkgs` used by `nixGL` and `program`.

### Use an overlay

Add nixGL as a flake input:


```Nix
{
  inputs = {
    nixgl.url = "github:guibou/nixGL";
  };
  outputs = { nixgl, ... }: { };
}
```

Then, use the flake's `overlay` attr:

```Nix
{
  outputs = { nixgl, nixpkgs, ... }:
  let
    pkgs = import nixpkgs {
      system = "x86_64-linux";
      overlays = [ nixgl.overlay ];
    };
  in
  # You can now reference pkgs.nixgl.nixGLIntel, etc.
  { }
}
```

## Installation from source

```bash
$ git clone https://github.com/guibou/nixGL
$ cd nixGL
$ nix-env -f ./ -iA <your desired wrapper name>
```

# Usage

Just launch the program you want prefixed by the right wrapper.

For example, for OpenGL programs:

```bash
$ nixGL program args                 # For the `nixGLDefault` wrapper, recommended.
$ nixGLNvidia program args
$ nixGLIntel program args
$ nixGLNvidiaBumblebee program args
```

For Vulkan programs:

```bash
$ nixVulkanNvidia program args
$ nixVulkanIntel program args
```

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
nix-build -A auto.nixGLNvidia --argstr nvidiaVersion 440.82
```

(or `nixGLNvidiaBumblebee`, `nixVulkanNividia`)


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

`nixGLCommon nixGLXXX` can be used to get `nixGL` executable which fallback to `nixGLXXX`. It is a shorter name for people with only one OpenGL configuration.

For example:

```
nix-build -E "with import ./default.nix {}; nixGLCommon nixGLIntel"
```

# Limitations

`nixGL` is badly tested, mostly because it is difficult to test automatically in a continuous integration context because you need access to different type of hardware.

Some OpenGL configurations may not work, for example AMD proprietary drivers. There is no fundamental limitation, so if you want support for theses configurations, open an issue.

# Hacking

One great way to contribute to nixGL is to run the test suite. Just run
`./Test.hs` in the main directory and check that all the test relevant to your
hardware are green.
