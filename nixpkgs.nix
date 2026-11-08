let
  rev = "1d2b03b1c775b7da6b9359ee5f20ad271f569042";
in
import (fetchTarball {
  url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
})
