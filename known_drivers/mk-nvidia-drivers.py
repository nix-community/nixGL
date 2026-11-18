#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p "python3.withPackages (ps: [ ps.beautifulsoup4 ps.requests ])"

import requests
from bs4 import BeautifulSoup
import re
import subprocess
from subprocess import CalledProcessError
import os
import json

CLEANUP=True

headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}

nv = requests.get("https://download.nvidia.com/XFree86/Linux-x86_64/", headers=headers)

soup = BeautifulSoup(nv.content.decode(), 'html.parser')
dirs = [e.text for e in soup.select(".dir")]
vers = [re.sub("/$", "", t) for t in dirs if not re.search("^..$|-", t)]
url_tmpl = "https://download.nvidia.com/XFree86/Linux-x86_64/{v}/NVIDIA-Linux-x86_64-{v}.run"

nv_datacenter = requests.get(
    "https://developer.nvidia.com/datacenter-driver-archive", headers=headers)
soup_datacenter = BeautifulSoup(nv_datacenter.content.decode(), 'html.parser')
vers_datacenter = [a.text.split(" ")[-1]  for a \
                   in soup_datacenter.select("a") \
                   if a.text.find("Driver") != -1]

extra_vers = list(set(vers_datacenter) - set(vers))
extra_url_tmpl = "https://us.download.nvidia.com/tesla/{v}/NVIDIA-Linux-x86_64-{v}.run"

def process_output(o):
    lines = o.decode().split("\n")
    pth_line = lines[0]
    store_pth = re.search("'(.*)'", pth_line).group(1)
    store_hash = lines[1]

    return (store_pth, store_hash)

def do_cleanup(pth):
    print(f"Attempting cleanup of {pth}")
    try:
        subprocess.check_output(["nix-store", "--delete", pth])
        print("Cleanup success.")
    except CalledProcessError:
        print("Cleanup failed.")

def do_download(version, url_tmpl):
    try:
        url = url_tmpl.format(v = version)
        print(f"Trying download of {url}")
        out = subprocess.check_output(["nix-prefetch-url", url], stderr = subprocess.STDOUT, timeout=600)
        store_pth, store_hash = process_output(out)
        if CLEANUP:
            do_cleanup(store_pth)

        return {"sha256" : store_hash, "known_url" : url}

    except CalledProcessError:
        print("Download Failed")
        return None

if os.path.exists("driver-versions.json"):
    print("driver-versions.json already exists, parsing known versions to skip re-downloads.")
    with open("driver-versions.json") as f:
        drivers = json.load(f)
else:
    drivers = {}

for v in vers:
    if v not in drivers.keys():
        result = do_download(v, url_tmpl)
        if result is not None:
            drivers[v] = result

for v in extra_vers:
     if v not in drivers.keys():
         result = do_download(v, extra_url_tmpl)
         if result is not None:
             drivers[v] = result

with open("driver-versions.json", "wt") as f:
    json.dump(drivers, f, indent=2)
