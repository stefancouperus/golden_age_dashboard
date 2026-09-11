"""Download a versioned snapshot of the corrected research data, without edits.

Run explicitly when updating the website's research snapshot; normal website
builds use the checked-in snapshot and do not fetch a moving upstream branch.
"""
import hashlib
import json
from pathlib import Path
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
REPO = "hjmschoonvelde/gouden_eeuw_project"
PATH = "data/derived/ge_final_45_24.csv"

def fetch(url):
    with urlopen(Request(url, headers={"User-Agent": "Golden-Age-Politics-data-sync"}), timeout=60) as response:
        return response.read()

commit = json.loads(fetch(f"https://api.github.com/repos/{REPO}/commits/main"))["sha"]
source = f"https://raw.githubusercontent.com/{REPO}/{commit}/{PATH}"
content = fetch(source)
target = ROOT / "data/research"
target.mkdir(parents=True, exist_ok=True)
(target / "ge_final_45_24.csv").write_bytes(content)
(target / "source.json").write_text(json.dumps({
    "repository": f"https://github.com/{REPO}", "commit": commit,
    "path": PATH, "url": f"https://github.com/{REPO}/blob/{commit}/{PATH}",
    "sha256": hashlib.sha256(content).hexdigest(),
}, indent=2) + "\n")
print(f"Downloaded corrected research snapshot at {commit}.")
