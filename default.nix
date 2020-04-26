{ ## Nvidia informations.
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
  nixpkgs = pkgs {config = {allowUnfree = true;};};
in
  nixpkgs.callPackage ./nixGL.nix {
    inherit nvidiaVersion nvidiaHash enable32bits;
  }
