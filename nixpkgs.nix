let
  rev = "4f6d8095fd51";
in
import (fetchTarball {
  url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
})
