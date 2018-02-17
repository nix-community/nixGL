This tool tries to solve the "OpenGL" problem on nix.

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
```

Build / install

```
cd nixGL
nix-build -A XXX
nix-env -i ./result
```

XXX can be one of:

- `nixGLNvidia`: Nvidia driver without bumblebee (should work, but done from memory: please open a bug report if any issue)
- `nixGLNvidiaBumblebee`: Nvidia driver with bumblebee (tested)
- `nixGLIntel`: Intel driver (tested)

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

The idea is really simple and should work reliably in most cases. It
can be easily extended to AMD drivers, I just don't have the hardware
to test. Contact me.

*Important*: You need an host system driver which match the nixpkgs one. For example, at the time of this writing, nixpkgs contains nvidia `390.25`. Your host system must contain the same version. This limitation can be lifted by using a different version of nixpkgs:

```shell
export NIX_PATH=nixpkgs=https://github.com/NixOS/nixpkgs-channels/archive/nixos-14.12.tar.gz
nix-build -A nixGLNvidia
```

Contact me if this limitation is too important, it may be easy to automate this process.