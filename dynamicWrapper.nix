{
  pkgs,
  writeTextFile,
  runtimeShell,
  gnugrep,
  shellcheck,
  pcre
}:

writeTextFile rec {
  name = "nixGL";
  text = ''#!${runtimeShell}

  driver_file=/proc/driver/nvidia/version

  vers=$(${gnugrep}/bin/grep "Module" "$driver_file"  |\
        ${gnugrep}/bin/grep -E -o "([0-9]{2,3}\.[0-9]{2,3}\.[0-9]{2,3})")
  if [ -z "$vers" ]; then
    echo "Failed to parse your driver version from $driver_file. Does $driver_file exist?"
    echo "Consider using nixGLNvidia-<version> directly instead."
    exit 1
  fi

  if ! command -v nixGLNvidia-"$vers" &> /dev/null; then
    echo "nixGLNvidia wrapper not found for $vers"
    exit 1
  fi

  exec nixGLNvidia-"$vers" "$@"
  '';
  executable = true;
  destination = "/bin/${name}";
  checkPhase = ''
  ${shellcheck}/bin/shellcheck "$out/bin/${name}"

  # Check that all the files listed in the output binary exists
  for i in $(${pcre}/bin/pcregrep  -o0 '/nix/store/.*?/[^ ":]+' $out/bin/${name})
  do
    ls $i > /dev/null || (echo "File $i, referenced in $out/bin/${name} does not exists."; exit -1)
  done
  '';
}
