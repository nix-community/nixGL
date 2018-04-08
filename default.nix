{ system ? builtins.currentSystem,
  nvidiaVersion ? null
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

  nixNvidiaWrapper = api: runCommand "nix${api}Nvidia-${version}" {
    buildInputs = [ nvidiaLibsOnly ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch ${api} application on system other than NixOS - Nvidia version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nix${api}Nvidia << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidiaLibsOnly}/lib
      "\$@"
      FOO

      chmod u+x $out/bin/nixGLNvidia
      '';

  nixGLNvidia = nixNvidiaWrapper "GL";

  nixVulkanNvidia = nixNvidiaWrapper "Vulkan";

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

  nixVulkanIntel = runCommand "nixVulkanIntel-${version}" {
     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch Vulkan application on system other than NixOS - Intel version";
         homepage = "https://github.com/guibou/nixGL";
     };
   } ''
     mkdir -p "$out/bin"
     cat > "$out/bin/nixVulkanIntel" << EOF
     #!/usr/bin/env bash
     if [ ! -z "$LD_LIBRARY_PATH" ]; then
       echo "Warning, nixVulkanIntel overwriting existing LD_LIBRARY_PATH" 1>&2
     fi
     export LD_LIBRARY_PATH=${lib.makeLibraryPath [
       zlib
       libdrm
       xorg.libX11
       xorg.libxcb
       xorg.libxshmfence
       wayland
       gcc.cc
     ]}
     exec "\$@"
     EOF
     chmod u+x "$out/bin/nixVulkanIntel"
     ${shellcheck}/bin/shellcheck "$out/bin/nixVulkanIntel"
    '';
}
