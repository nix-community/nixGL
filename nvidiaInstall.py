#! /usr/bin/env nix-shell
#! nix-shell -i python3 -p python3
import sys
import subprocess

nvidiaVersion = sys.argv[1]
tool = sys.argv[2]

nvidiaUrl = f"http://download.nvidia.com/XFree86/Linux-x86_64/{nvidiaVersion}/NVIDIA-Linux-x86_64-{nvidiaVersion}.run"

nvidiaHash = subprocess.check_output(["nix-prefetch-url", nvidiaUrl]).strip()

subprocess.check_call(["nix-build", "-A", tool, "--argstr", "nvidiaVersion", nvidiaVersion, "--argstr", "nvidiaHash", nvidiaHash])
