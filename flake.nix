{
  description = "A wrapper tool for nix OpenGL applications";
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, flake-utils, nixpkgs }:
    {
      overlay = _: prev: {
        nixgl = import ./default.nix { pkgs = prev; };
      };
    }
    // flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlay ];
      };
    in
    {
      packages.nixGLIntel = pkgs.nixgl.nixGLIntel;
      packages.nixVulkanIntel = pkgs.nixgl.nixVulkanIntel;
    });
}
