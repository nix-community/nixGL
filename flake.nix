{
  description = "A wrapper tool for nix OpenGL applications";

  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { self, nixpkgs, flake-utils }:
    (flake-utils.lib.eachDefaultSystem (system:
      let
        isIntelX86Platform = system == "x86_64-linux";
        pkgs = import ./default.nix {
          pkgs = nixpkgs.legacyPackages.${system};
          enable32bits = isIntelX86Platform;
          enableIntelX86Extensions = isIntelX86Platform;
        };
      in rec {

        packages = {
          # makes it easy to use "nix run nixGL --impure -- program"
          default = pkgs.auto.nixGLDefault;

          nixGLDefault = pkgs.auto.nixGLDefault;
          nixGLNvidia = pkgs.auto.nixGLNvidia;
          nixGLNvidiaBumblebee = pkgs.auto.nixGLNvidiaBumblebee;
          nixGLIntel = pkgs.nixGLIntel;
          nixVulkanNvidia = pkgs.auto.nixVulkanNvidia;
          nixVulkanIntel = pkgs.nixVulkanIntel;
        };

        # deprecated attributes for retro compatibility
        defaultPackage = packages;
      })) // rec {
        # deprecated attributes for retro compatibility
        overlay = overlays.default;
        overlays.default = final: _:
          let isIntelX86Platform = final.system == "x86_64-linux";
          in {
            nixgl = import ./default.nix {
              pkgs = final;
              enable32bits = isIntelX86Platform;
              enableIntelX86Extensions = isIntelX86Platform;
            };
          };
      };
}
