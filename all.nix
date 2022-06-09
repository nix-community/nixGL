let
  pkgs = import ./nixpkgs.nix { config = { allowUnfree = true; }; };

  pure = pkgs.recurseIntoAttrs (pkgs.callPackage ./nixGL.nix {
    nvidiaVersion = "440.82";
    nvidiaHash = "edd415acf2f75a659e0f3b4f27c1fab770cf21614e84a18152d94f0d004a758e";
  });

  versionFile440 = (pkgs.callPackage ./nixGL.nix {
    nvidiaVersionFile = pkgs.writeText "nvidia-version-440.82" ''
      NVRM version: NVIDIA UNIX x86_64 Kernel Module  440.82  Wed Apr  1 20:04:33 UTC 2020
      GCC version:  gcc version 9.3.0 (Arch Linux 9.3.0-1)
    '';
  });

  versionFile510 = (pkgs.callPackage ./nixGL.nix {
    nvidiaVersionFile = pkgs.writeText "nvidia-version-510.54" ''
      NVRM version: NVIDIA UNIX x86_64 Kernel Module  510.54  Wed Apr  1 20:04:33 UTC 2020
      GCC version:  gcc version 9.3.0 (Arch Linux 9.3.0-1)
    '';
  });
in
  (with pure; [nixGLIntel nixVulkanNvidia nixGLNvidia nixVulkanIntel])
   ++ (with versionFile440.auto; [nixGLNvidia nixGLDefault nixVulkanNvidia])
   ++ (with versionFile510.auto; [nixGLNvidia nixGLDefault nixVulkanNvidia])
