let
  rev = "10e687235226880ed5e9f33f1ffa71fe60f2638a";
in
import (fetchTarball {
  url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
})
