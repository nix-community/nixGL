{ system ? builtins.currentSystem }:

let
  pkgs = import <nixpkgs> { inherit system; };
in
rec {
  nixGl = pkgs.stdenv.mkDerivation rec {
     name = "nixGL-${version}";
     version = "1.0.0";

     buildInputs = [ pkgs.python3 pkgs.which pkgs.binutils ];
     outputs = [ "out" ];

     src = ./.;

     buildPhase = ''
        mkdir -p $out/bin
	'';

     installPhase = ''
        cp nixGL $out/bin
	'';

     meta = with pkgs.stdenv.lib; {
         description = "A tool to launch OpenGL application on system other than NixOS";
         homepage = "https://github.com/guibou/nixGL";
     };
  };
}
