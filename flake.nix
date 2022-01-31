{
  description = "A wrapper tool for nix OpenGL applications";
  outputs = { self }: {
    overlay = _: prev: {
      nixgl = import ./default.nix { pkgs = prev; };
    };
  };
}
