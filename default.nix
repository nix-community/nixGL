{ system ? builtins.currentSystem,
  nvidiaVersion ? null,
  nvidiaHash ? null,
  pkgs ? import <nixpkgs>
}:

let
  overlay = self: super:
  {
     linuxPackages = super.linuxPackages //
     {
         nvidia_x11 = (super.linuxPackages.nvidia_x11.override {
          }).overrideAttrs(oldAttrs: rec {
            name = "nvidia-${nvidiaVersion}";
            src = super.fetchurl {
              url = "http://download.nvidia.com/XFree86/Linux-x86_64/${nvidiaVersion}/NVIDIA-Linux-x86_64-${nvidiaVersion}.run";
              sha256 = nvidiaHash;
            };
            useGLVND = true;
          });
     };
  };

  nixpkgs = pkgs { overlays = [overlay]; config = {allowUnfree = true;};};
in
with nixpkgs;
rec {
  nvidia = linuxPackages.nvidia_x11;

  nvidiaLibsOnly = nvidia.override {
      libsOnly = true;
      kernel = null;
  };

  nixGLNvidiaBumblebee = runCommand "nixGLNvidiaBumblebee" {
    buildInputs = [ nvidia bumblebee ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS - Nvidia bumblebee version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nixGLNvidiaBumblebee << FOO
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${nvidia}/lib:\$LD_LIBRARY_PATH
      ${bumblebee}/bin/optirun --ldpath ${libglvnd}/lib:${nvidia}/lib "\$@"
      FOO

      chmod u+x $out/bin/nixGLNvidiaBumblebee
      '';

  nixNvidiaWrapper = api: runCommand "nix${api}Nvidia" {
    buildInputs = [ nvidiaLibsOnly ];

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch ${api} application on system other than NixOS - Nvidia version";
         homepage = "https://github.com/guibou/nixGL";
     };
    } ''
      mkdir -p $out/bin
      cat > $out/bin/nix${api}Nvidia << 'FOO'
      #!/usr/bin/env sh
      ${lib.optionalString (api == "Vulkan") ''export VK_LAYER_PATH=${nixpkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d''}

      export LD_LIBRARY_PATH=${lib.makeLibraryPath ([
        libglvnd
        nvidiaLibsOnly
      ] ++ lib.optional (api == "Vulkan") nixpkgs.vulkan-validation-layers)
      }''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      "\$@"
      FOO

      chmod u+x $out/bin/nix${api}Nvidia
      '';

  nixGLNvidia = nixNvidiaWrapper "GL";

  nixVulkanNvidia = nixNvidiaWrapper "Vulkan";

  nixGLIntel = runCommand "nixGLIntel" {
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
      export LD_LIBRARY_PATH=${mesa_drivers}/lib:\$LD_LIBRARY_PATH
      "\$@"
      FOO

      chmod u+x $out/bin/nixGLIntel
      '';

  nixVulkanIntel = runCommand "nixVulkanIntel" {
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
     ]}:\$LD_LIBRARY_PATH
     exec "\$@"
     EOF
     chmod u+x "$out/bin/nixVulkanIntel"
     ${shellcheck}/bin/shellcheck "$out/bin/nixVulkanIntel"
    '';

  nixGLCommon = nixGL:
    runCommand "nixGLCommon" {
       buildInuts = [nixGL];
    }
    ''
       mkdir -p "$out/bin"
       cp "${nixGL}/bin/${nixGL.name}" "$out/bin/nixGL";
    '';
}
