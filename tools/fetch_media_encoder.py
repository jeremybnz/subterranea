"""Fetch the Windows media encoder from the published imageio-ffmpeg wheel."""
import io, json, urllib.request, zipfile
from pathlib import Path
folder=Path(__file__).resolve().parent/"runtime"
folder.mkdir(exist_ok=True)
with urllib.request.urlopen("https://pypi.org/pypi/imageio-ffmpeg/json",timeout=30) as response: package=json.load(response)
item=next(value for value in package["urls"] if value["filename"].endswith("win_amd64.whl"))
with urllib.request.urlopen(item["url"],timeout=45) as response: data=response.read()
import hashlib
assert hashlib.sha256(data).hexdigest()==item["digests"]["sha256"]
with zipfile.ZipFile(io.BytesIO(data)) as archive:
    name=next(name for name in archive.namelist() if name.endswith(".exe") and "ffmpeg" in name)
    (folder/"ffmpeg.exe").write_bytes(archive.read(name))
(folder/"media_encoder_source.json").write_text(json.dumps({"package":package["info"]["name"],"version":package["info"]["version"],"url":item["url"],"sha256":item["digests"]["sha256"]},indent=2),encoding="utf-8")
print("Media encoder ready for the local gameplay trailer.")
