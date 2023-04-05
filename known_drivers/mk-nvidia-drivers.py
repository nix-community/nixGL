import requests
from bs4 import BeautifulSoup
import re
import subprocess
from subprocess import CalledProcessError

CLEANUP=True

headers = {'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.95 Safari/537.36'}

nv = requests.get("https://download.nvidia.com/XFree86/Linux-x86_64/", headers=headers)

soup = BeautifulSoup(nv.content.decode(), 'html.parser')
dirs = [e.text for e in soup.select(".dir")]
vers = [re.sub("/$", "", t) for t in dirs if not re.search("^..$|-", t)]

def process_output(o):
    lines = o.decode().split("\n")
    pth_line = lines[0]
    store_pth = re.search("'(.*)'", pth_line).group(1)
    store_hash = lines[1]

    return (store_pth, store_hash)

with open("driver-versions.nix", "wt") as f:
    print("[", file=f)
    for v in vers:
        try: 
            url = f"https://download.nvidia.com/XFree86/Linux-x86_64/{v}/NVIDIA-Linux-x86_64-{v}.run"
            print(f"Trying download of {url}")
            out = subprocess.check_output(["nix-prefetch-url", url], stderr = subprocess.STDOUT)
            store_pth, store_hash = process_output(out)
            if CLEANUP:
                print(f"Attempting cleanup of {store_pth}")
                try:
                    subprocess.check_output(["nix-store", "--delete", store_pth])
                    print("Cleanup success.")
                except CalledProcessError:
                    print("Cleanup failed.")
                    pass
            print(f'{{ version = "{v}"; sha256 = "{store_hash}"; }}', file=f)                  
        except CalledProcessError:
            print("Download Failed")
            pass
    print("]", file=f)





