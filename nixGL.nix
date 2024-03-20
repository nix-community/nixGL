{ # # Nvidia informations.
# Version of the system kernel module. Let it to null to enable auto-detection.
nvidiaVersion ? null,
# Hash of the Nvidia driver .run file. null is fine, but fixing a value here
# will be more reproducible and more efficient.
nvidiaHash ? null,
# Alternatively, you can pass a path that points to a nvidia version file
# and let nixGL extract the version from it. That file must be a copy of
# /proc/driver/nvidia/version. Nix doesn't like zero-sized files (see
# https://github.com/NixOS/nix/issues/3539 ).
nvidiaVersionFile ? null,
# Enable 32 bits driver
# This is one by default, you can switch it to off if you want to reduce a
# bit the size of nixGL closure.
enable32bits ? stdenv.hostPlatform.isx86
, stdenv, writeTextFile, shellcheck, pcre, runCommand, linuxPackages
, fetchurl, lib, runtimeShell, bumblebee, libglvnd, vulkan-validation-layers
, mesa, libvdpau-va-gl, intel-media-driver, pkgsi686Linux, driversi686Linux
, zlib, libdrm, xorg, wayland, gcc, zstd }:

let
  writeExecutable = { name, text }:
    writeTextFile {
      inherit name text;

      executable = true;
      destination = "/bin/${name}";

      checkPhase = ''
        ${shellcheck}/bin/shellcheck "$out/bin/${name}"

        # Check that all the files listed in the output binary exists
        for i in $(${pcre}/bin/pcregrep  -o0 '/nix/store/.*?/[^ ":]+' $out/bin/${name})
        do
          ls $i > /dev/null || (echo "File $i, referenced in $out/bin/${name} does not exists."; exit -1)
        done
      '';
    };

    writeNixGL = name: vadrivers: writeExecutable {
      inherit name;
      # add the 32 bits drivers if needed
      text = let
        mesa-drivers = [ mesa.drivers ]
          ++ lib.optional enable32bits pkgsi686Linux.mesa.drivers;
        libvdpau = [ libvdpau-va-gl ]
          ++ lib.optional enable32bits pkgsi686Linux.libvdpau-va-gl;
        glxindirect = runCommand "mesa_glxindirect" { } (''
          mkdir -p $out/lib
          ln -s ${mesa.drivers}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
        '');
      in ''
        #!${runtimeShell}
        export LIBGL_DRIVERS_PATH=${lib.makeSearchPathOutput "lib" "lib/dri" mesa-drivers}
        export LIBVA_DRIVERS_PATH=${lib.makeSearchPathOutput "out" "lib/dri" (mesa-drivers ++ vadrivers)}
        ${''export __EGL_VENDOR_LIBRARY_FILENAMES=${mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json${
          lib.optionalString enable32bits
          ":${pkgsi686Linux.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json"
          }"''${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}"''
        }
        export LD_LIBRARY_PATH=${lib.makeLibraryPath mesa-drivers}:${lib.makeSearchPathOutput "lib" "lib/vdpau" libvdpau}:${glxindirect}/lib:${lib.makeLibraryPath [libglvnd]}"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        exec "$@"
      '';
    };
  top = rec {
    /*
    It contains the builder for different nvidia configuration, parametrized by
    the version of the driver and sha256 sum of the driver installer file.
    */
    nvidiaPackages = { version, sha256 ? null }: rec {
      nvidiaDrivers = (linuxPackages.nvidia_x11.override { }).overrideAttrs
        (oldAttrs: rec {
          pname = "nvidia";
          name = "nvidia-x11-${version}-nixGL";
          inherit version;
          src = let
            url =
              "https://download.nvidia.com/XFree86/Linux-x86_64/${version}/NVIDIA-Linux-x86_64-${version}.run";
          in if sha256 != null then
            fetchurl { inherit url sha256; }
          else
            builtins.fetchurl url;
          useGLVND = true;
          nativeBuildInputs = oldAttrs.buildInputs or [] ++ [zstd];
        });

      nvidiaLibsOnly = nvidiaDrivers.override {
        libsOnly = true;
        kernel = null;
      };

      nixGLNvidiaBumblebee = writeExecutable {
        name = "nixGLNvidiaBumblebee-${version}";
        text = ''
          #!${runtimeShell}
          export LD_LIBRARY_PATH=${
            lib.makeLibraryPath [ nvidiaDrivers ]
          }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
          ${
            bumblebee.override {
              nvidia_x11 = nvidiaDrivers;
              nvidia_x11_i686 = nvidiaDrivers.lib32;
            }
          }/bin/optirun --ldpath ${
            lib.makeLibraryPath ([ libglvnd nvidiaDrivers ]
              ++ lib.optionals enable32bits [
                nvidiaDrivers.lib32
                pkgsi686Linux.libglvnd
              ])
          } "$@"
        '';
      };

      # TODO: 32bit version? Not tested.
      nixNvidiaWrapper = api:
        writeExecutable {
          name = "nix${api}Nvidia-${version}";
          text = ''
            #!${runtimeShell}
            ${lib.optionalString (api == "Vulkan")
            "export VK_LAYER_PATH=${vulkan-validation-layers}/share/vulkan/explicit_layer.d"}
            NVIDIA_JSON=(${nvidiaLibsOnly}/share/glvnd/egl_vendor.d/*nvidia.json)
            ${lib.optionalString enable32bits "NVIDIA_JSON32=(${nvidiaLibsOnly.lib32}/share/glvnd/egl_vendor.d/*nvidia.json)"}

            ${''export __EGL_VENDOR_LIBRARY_FILENAMES=''${NVIDIA_JSON[*]}${
              lib.optionalString enable32bits
              '':''${NVIDIA_JSON32[*]}''
              }"''${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}"''
            }

              ${
                lib.optionalString (api == "Vulkan")
                ''export VK_ICD_FILENAMES=${nvidiaLibsOnly}/share/vulkan/icd.d/nvidia_icd.x86_64.json${
                  lib.optionalString enable32bits
                  ":${nvidiaLibsOnly.lib32}/share/vulkan/icd.d/nvidia_icd.i686.json"
                }"''${VK_ICD_FILENAMES:+:$VK_ICD_FILENAMES}"''
              }
              export LD_LIBRARY_PATH=${
                lib.makeLibraryPath ([ libglvnd nvidiaLibsOnly ]
                  ++ lib.optional (api == "Vulkan") vulkan-validation-layers
                  ++ lib.optionals enable32bits [
                    nvidiaLibsOnly.lib32
                    pkgsi686Linux.libglvnd
                  ])
              }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
              exec "$@"
          '';
        };

      # TODO: 32bit version? Not tested.
      nixGLNvidia = nixNvidiaWrapper "GL";

      # TODO: 32bit version? Not tested.
      nixVulkanNvidia = nixNvidiaWrapper "Vulkan";
    };


    nixGLMesa = writeNixGL "nixGLMesa" [  ];

    nixGLIntel = writeNixGL "nixGLIntel"
      ([ intel-media-driver ]
       ++ lib.optionals enable32bits [ pkgsi686Linux.intel-media-driver ]);

    nixVulkanMesa = writeExecutable {
      name = "nixVulkanIntel";
      text = let
        # generate a file with the listing of all the icd files
        icd = runCommand "mesa_icd" { } (
          # 64 bits icd
          ''
            ls ${mesa.drivers}/share/vulkan/icd.d/*.json > f
          ''
          #  32 bits ones
          + lib.optionalString enable32bits ''
            ls ${pkgsi686Linux.mesa.drivers}/share/vulkan/icd.d/*.json >> f
          ''
          # concat everything as a one line string with ":" as seperator
          + ''cat f | xargs | sed "s/ /:/g" > $out'');
      in ''
        #!${runtimeShell}
        if [ -n "$LD_LIBRARY_PATH" ]; then
          echo "Warning, nixVulkanIntel overwriting existing LD_LIBRARY_PATH" 1>&2
        fi
        export VK_LAYER_PATH=${vulkan-validation-layers}/share/vulkan/explicit_layer.d
        ICDS=$(cat ${icd})
        export VK_ICD_FILENAMES=$ICDS"''${VK_ICD_FILENAMES:+:$VK_ICD_FILENAMES}"
        export LD_LIBRARY_PATH=${
          lib.makeLibraryPath [
            zlib
            libdrm
            xorg.libX11
            xorg.libxcb
            xorg.libxshmfence
            wayland
            gcc.cc
          ]
        }"''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
        exec "$@"
      '';
    };

    nixVulkanIntel = nixVulkanMesa;

    nixGLCommon = nixGL:
      runCommand "nixGL" { } ''
        mkdir -p "$out/bin"
        # star because nixGLNvidia... have version prefixed name
        cp ${nixGL}/bin/* "$out/bin/nixGL";
      '';

    auto = let
      _nvidiaVersionFile = if nvidiaVersionFile != null then
        nvidiaVersionFile
      else
      # HACK: Get the version from /proc. It turns out that /proc is mounted
      # inside of the build sandbox and varies from machine to machine.
      #
      # builtins.readFile is not able to read /proc files. See
      # https://github.com/NixOS/nix/issues/3539.
        runCommand "impure-nvidia-version-file" {
          # To avoid sharing the build result over time or between machine,
          # Add an impure parameter to force the rebuild on each access.
          time = builtins.currentTime;
          preferLocalBuild = true;
          allowSubstitutes = false;
        } "cp /proc/driver/nvidia/version $out 2> /dev/null || touch $out";

      # The nvidia version. Either fixed by the `nvidiaVersion` argument, or
      # auto-detected. Auto-detection is impure.
      nvidiaVersionAuto = if nvidiaVersion != null then
        nvidiaVersion
      else
      # Get if from the nvidiaVersionFile
        let
          data = builtins.readFile _nvidiaVersionFile;
          versionMatch = builtins.match ".*Module  ([0-9.]+)  .*" data;
        in if versionMatch != null then builtins.head versionMatch else null;

      autoNvidia = nvidiaPackages {version = nvidiaVersionAuto; };
    in rec {
      # The output derivation contains nixGL which point either to
      # nixGLNvidia or nixGLIntel using an heuristic.
      nixGLDefault = if nvidiaVersionAuto != null then
        nixGLCommon autoNvidia.nixGLNvidia
      else
        nixGLCommon nixGLIntel;
    } // autoNvidia;
  };
in top // (if nvidiaVersion != null then
  top.nvidiaPackages {
    version = nvidiaVersion;
    sha256 = nvidiaHash;
  }
else
  { })
