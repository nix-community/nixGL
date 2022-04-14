{
  description = "A wrapper tool for nix OpenGL applications";

  inputs.nixpkgs.url = "nixpkgs/nixos-21.11";

  outputs = { self, nixpkgs }: {
    overlay = final: _: {
      nixgl = import ./default.nix { pkgs = final; };
    };

    # makes it easy to use "nix run nixGL --impure -- program"
    defaultPackage.x86_64-linux = (import ./default.nix { pkgs = nixpkgs.legacyPackages.x86_64-linux; }).auto.nixGLDefault;
  };
}
