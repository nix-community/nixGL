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
nixGL program
```

# Installation / Usage

Clone this git repository:

```
git clone https://github.com/guibou/nixGL
```

(Optional) installation:

```
cd nixGL
nix-build
nix-env -i ./result
```

Usage:

```
nixGL program args
```

# Limitations

The idea is really simple and should work reliably. However there is still two configurations variables hardcoded in the wrapper. Open a bug / pull request if this does not work on your distribution / driver.

## Library paths

The path of where the `libGL.so` library can be found on your system, usually `/usr/lib`.

## Name of the Nix package which contains `libGL.so`

This package will be ignored by the wrapper. It is currently hardcoded as `mesa-noglu` but this can be fixed.

