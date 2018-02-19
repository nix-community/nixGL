This tool tries to solve the "OpenGL" problem on nix.

# Quick start

Suppose you have a configuration with an nvidia card, host driver version `390.25`

```
# clone the repository
git clone https://github.com/guibou/nixGL
cd nixGL

# build and install the wrapper
nix-build -A nixGLNvidia --argstr nvidiaVersion 390.25
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

This library contains a wrapper which is able to launch GL application:

```
nixGLXXX program
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

For intel:

```
nix-build -A nixGLIntel
```

For NVIDIA alone:

```
nix-build -A nixGLNvidia --argstr nvidiaVersion 390.25
```

(replace `390.25` with the host driver version gathered earlier.)

For Nvidia with bumblebee:

```
nix-build -A nixGLNvidiaBumblebee --argstr nvidiaVersion 390.25
```

(replace `390.25` with the host driver version gathered earlier.)

## Install

```
nix-env -i ./result
```

(Note, you can iterate many time on this process to install as many driver as needed. Common example are `nixGLIntel` with `nixGLNvidiaBumblebee`)


# Usage

```
nixGLXXX program args
```

For example (on my dual GPU laptop):

```bash
$ nixGLIntel glxinfo | grep -i 'OpenGL version string'
OpenGL version string: 3.0 Mesa 17.3.3
$ nixGLNvidiaBumblebee glxinfo | grep -i 'OpenGL version string'
OpenGL version string: 4.6.0 NVIDIA 390.25
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
