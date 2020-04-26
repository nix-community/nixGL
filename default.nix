{ system ? builtins.currentSystem,
  ## Nvidia informations.
  # Version of the system kernel module. Let it to null to enable auto-detection.
  nvidiaVersion ? null,
  # Hash of the Nvidia driver .run file. null is fine, but fixing a value here
  # will be more reproducible and more efficient.
  nvidiaHash ? null,
  # Enable 32 bits driver
  # This is one by default, you can switch it to off if you want to reduce a
  # bit the size of nixGL closure.
  enable32bits ? true,
  pkgs ? import <nixpkgs>
}:

let
  # The nvidia version. Either fixed by the `nvidiaVersion` argument, or
  # auto-detected.
  _nvidiaVersion = if nvidiaVersion != null
  then nvidiaVersion
  else
    # This is the auto-detection mecanism. This is ugly.
    # We read /proc/driver/nvidia/version which is set by the Nvidia driver kernel module.
    # This fails if the nvidia driver kernel module is not loaded.
    # I'd like to just read the file using `${/proc/driver/nvidia/version}` and
    # then let nix invalidate the derivation if the content of this file
    # changes, but that's not possible, see
    # https://github.com/NixOS/nix/issues/3539
    # But /proc is readable at build time! So runCommand works fine.
    import (nixpkgs.runCommand "auto-detect-nvidia" {
      time = builtins.currentTime;
      }
      ''
        # Written this way so if the version file does not exists, the script crashs
        VERSION="$(${nixpkgs.pcre}/bin/pcregrep -o1 'Module +([0-9]+\.[0-9]+)' /proc/driver/nvidia/version)"
        echo "\"$VERSION\"" > $out
      '');

  addNvidiaVersion = drv: drv.overrideAttrs(oldAttrs: {
    name = oldAttrs.name + "-${_nvidiaVersion}";
  });
  
  overlay = self: super:
  {
     linuxPackages = super.linuxPackages //
     {
         nvidia_x11 = (super.linuxPackages.nvidia_x11.override {
          }).overrideAttrs(oldAttrs: rec {
            name = "nvidia-${_nvidiaVersion}";
            src = let url ="http://download.nvidia.com/XFree86/Linux-x86_64/${_nvidiaVersion}/NVIDIA-Linux-x86_64-${_nvidiaVersion}.run";
                  in if nvidiaHash != null
                     then super.fetchurl {
                       inherit url;
                       sha256 = nvidiaHash;
                     } else
                       builtins.fetchurl url;
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
  nixGLNvidiaBumblebee = addNvidiaVersion (writeExecutable {
    name = "nixGLNvidiaBumblebee";
    text = ''
      #!/usr/bin/env sh
      export LD_LIBRARY_PATH=${lib.makeLibraryPath [nvidia]}:$LD_LIBRARY_PATH
      ${bumblebee}/bin/optirun --ldpath ${lib.makeLibraryPath [libglvnd nvidia]} "$@"
      '';
  });

  # TODO: 32bit version? Not tested.
  nixNvidiaWrapper = api: addNvidiaVersion (writeExecutable {
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
  });

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
