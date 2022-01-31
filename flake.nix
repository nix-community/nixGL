{
  description = "A wrapper tool for nix OpenGL applications";
  outputs = { self }: {
    overlay = final: _: {
      nixgl = import ./default.nix { pkgs = final; };
    };
  };
}
