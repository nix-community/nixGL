{ system ? builtins.currentSystem,
  nvidiaVersion ? null,
  nvidiaHash ? null,
  # Enable 32 bits driver
  # This is one by default, you can switch it to off if you want to reduce a
  # bit the size of nixGL closure.
  enable32bits ? true,
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

  # TODO: 32bit version? Looks like it works fine without anything special.
  nixGLNvidiaBumblebee = writeExecutable {
    name = "nixGLNvidiaBumblebee";
    text = ''
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${lib.makeLibraryPath [nvidia]}:$LD_LIBRARY_PATH
      ${bumblebee}/bin/optirun --ldpath ${lib.makeLibraryPath [libglvnd nvidia]} "$@"
      '';
  };

  # TODO: 32bit version? Not tested.
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

  # TODO: 32bit version? Not tested.
  nixGLNvidia = nixNvidiaWrapper "GL";

  # TODO: 32bit version? Not tested.
  nixVulkanNvidia = nixNvidiaWrapper "Vulkan";

  nixGLIntel = writeExecutable {
    name = "nixGLIntel";
    # add the 32 bits drivers if needed
    text = let
      drivers = [mesa_drivers] ++ lib.optional enable32bits pkgsi686Linux.mesa_drivers;
    in ''
      #!/usr/bin/env sh
      export LIBGL_DRIVERS_PATH=${lib.makeSearchPathOutput "lib" "lib/dri" drivers}
      export LD_LIBRARY_PATH=${
        lib.makeLibraryPath drivers
        }:$LD_LIBRARY_PATH
      "$@"
      '';
  };

  # TODO: 32 bit version? Not tested.
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
