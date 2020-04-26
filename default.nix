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

  writeExecutable = { name, text } : nixpkgs.writeTextFile {
    inherit name text;

    executable = true;
    destination = "/bin/${name}";


    checkPhase = ''
       ${nixpkgs.shellcheck}/bin/shellcheck "$out/bin/${name}"

       # Check that all the files listed in the output binary exists
       for i in $(${nixpkgs.pcre}/bin/pcregrep  -o0 '/nix/store/.*?/[^ ":]+' $out/bin/${name})
       do
         ls $i > /dev/null || (echo "File $i, referenced in $out/bin/${name} does not exists."; exit -1)
       done
    '';
  };

in
with nixpkgs;
rec {
  nvidia = linuxPackages.nvidia_x11;

  nvidiaLibsOnly = nvidia.override {
      libsOnly = true;
      kernel = null;
  };

  nixGLNvidiaBumblebee = writeExecutable {
    name = "nixGLNvidiaBumblebee";
    text = ''
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${lib.makeLibraryPath [nvidia]}:$LD_LIBRARY_PATH
      ${bumblebee}/bin/optirun --ldpath ${lib.makeLibraryPath [libglvnd nvidia]} "$@"
      '';
  };

  nixNvidiaWrapper = api: writeExecutable {
    name = "nix${api}Nvidia";
    text = ''
      #!/usr/bin/env sh
      ${lib.optionalString (api == "Vulkan") ''export VK_LAYER_PATH=${nixpkgs.vulkan-validation-layers}/share/vulkan/explicit_layer.d''}

      export LD_LIBRARY_PATH=${lib.makeLibraryPath ([
        libglvnd
        nvidiaLibsOnly
      ] ++ lib.optional (api == "Vulkan") nixpkgs.vulkan-validation-layers)
      }:''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      "$@"
      '';
  };

  nixGLNvidia = nixNvidiaWrapper "GL";

  nixVulkanNvidia = nixNvidiaWrapper "Vulkan";

  nixGLIntel = writeExecutable {
    name = "nixGLIntel";
    text = ''
      #!/usr/bin/env sh
      export LIBGL_DRIVERS_PATH=${lib.makeSearchPathOutput "lib" "lib/dri" [mesa_drivers]}
      export LD_LIBRARY_PATH=${
        lib.makeLibraryPath [
        mesa_drivers]
        }:$LD_LIBRARY_PATH
      "$@"
      '';
  };

  nixVulkanIntel = writeExecutable {
    name = "nixVulkanIntel";
    text = ''
     #!/usr/bin/env bash
     if [ -n "$LD_LIBRARY_PATH" ]; then
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
     ]}:$LD_LIBRARY_PATH
     exec "$@"
     '';
  };

  nixGLCommon = nixGL:
    runCommand "nixGLCommon" {
       buildInuts = [nixGL];
    }
    ''
       mkdir -p "$out/bin"
       cp "${nixGL}/bin/${nixGL.name}" "$out/bin/nixGL";
    '';
}
