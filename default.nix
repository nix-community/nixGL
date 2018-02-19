{ system ? builtins.currentSystem }:

let
  pkgs = import <nixpkgs> { inherit system; };

  version = "1.0.0";
in
with pkgs;
rec {
  nvidiaLibsOnly = linuxPackages.nvidia_x11.override {
    libsOnly = true;
    kernel = null;
  };

  nixGLNvidiaBumblebee = runCommand "nixGLNvidiaBumblebee-${version}" {
    buildInputs = [ libglvnd nvidiaLibsOnly bumblebee ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Nvidia bumblebee version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLNvidiaBumblebee << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidiaLibsOnly}/lib
      ${bumblebee}/bin/optirun --ldpath ${libglvnd}/lib "\$@"
      FOO

      chmod u+x $out/bin/nixGLNvidiaBumblebee
      '';

  nixGLNvidia = runCommand "nixGLNvidia-${version}" {
    buildInputs = [ libglvnd nvidiaLibsOnly ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Nvidia version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLNvidia << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidiaLibsOnly}/lib:${libglvnd}/lib
      "\$@"
      FOO

      chmod u+x $out/bin/nixGLNvidia
      '';

  nixGLIntel = runCommand "nixGLIntel-${version}" {
    buildInputs = [ mesa_drivers ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Intel version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLIntel << FOO
      #!/usr/bin/env sh
      export LIBGL_DRIVERS_PATH=${mesa_drivers}/lib/dri
      "\$@"
      FOO

      chmod u+x $out/bin/nixGLIntel
      '';
}
