{ system ? builtins.currentSystem,
  nvidiaVersion ? null,
  atiUrl ? null,
  atiVersion ? null
}:

let
  pkgs = import <nixpkgs> { inherit system; };

  version = "1.0.0";
in
with pkgs;
rec {
  nvidiaLibsOnly = (linuxPackages.nvidia_x11.override {
    libsOnly = true;
    kernel = null;
  }).overrideAttrs(oldAttrs: rec {
    name = "nvidia-${nvidiaVersion}";
    src = fetchurl {
      url = "http://download.nvidia.com/XFree86/Linux-x86_64/${nvidiaVersion}/NVIDIA-Linux-x86_64-${nvidiaVersion}.run";
      sha256 = null;
    };
    useGLVND = 0;
  });

  ati = (linuxPackages.ati_drivers_x11.override {
    libsOnly = true;
    kernel = null;
  }).overrideAttrs(oldAttrs : rec {
    name = "ati_drivers-${atiVersion}";
    src = fetchurl {
      url = atiUrl;
      sha256 = null;
      curlOpts = "--referer http://support.amd.com/en-us/download/desktop?os=Linux+x86_64";
    };
  });

  nixGLNvidiaBumblebee = runCommand "nixGLNvidiaBumblebee-${version}" {
    buildInputs = [ nvidiaLibsOnly bumblebee ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Nvidia bumblebee version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLNvidiaBumblebee << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidiaLibsOnly}/lib
      ${bumblebee}/bin/optirun "\$@"
      FOO

      chmod u+x $out/bin/nixGLNvidiaBumblebee
      '';

  nixGLNvidia = runCommand "nixGLNvidia-${version}" {
    buildInputs = [ nvidiaLibsOnly ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Nvidia version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLNvidia << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidiaLibsOnly}/lib
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

  nixGLAti = runCommand "nixGLAti-${version}" {
    buildInputs = [ mesa_drivers ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Ati version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLAti << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${ati}/lib
      "\$@"
      FOO

      chmod u+x $out/bin/nixGLAti
      '';
}
