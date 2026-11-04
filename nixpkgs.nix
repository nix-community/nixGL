let
  rev = "93b21a67cd0d2a3535dcbc013777b8f5b51511a8";
in
import (fetchTarball {
  url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
})
