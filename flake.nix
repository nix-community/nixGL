{
  description = "A wrapper tool for nix OpenGL applications";

  outputs = { self, nixpkgs }: let 
    pkgs = import ./default.nix { pkgs = nixpkgs.legacyPackages.x86_64-linux; };
  in rec {
    overlays.default = final: _: {
      nixgl = import ./default.nix { pkgs = final; };
    };

    packages.x86_64-linux = {
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
    defaultPackage.x86_64-linux = packages.x86_64-linux.default;
    overlay = overlays.default;
  };
}
