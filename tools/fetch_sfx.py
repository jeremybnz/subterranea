"""Fetch the official free CC0 pack using its published download action."""
from pathlib import Path
import hashlib,http.cookiejar,json,re,urllib.request,zipfile
ROOT=Path(__file__).resolve().parents[1];DEST=ROOT/"tools/runtime";DEST.mkdir(parents=True,exist_ok=True)
page="https://kenney.nl/assets/sci-fi-sounds"
client=urllib.request.build_opener(urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()));client.addheaders=[("User-Agent","Mozilla/5.0"),("Referer",page)]
with client.open(page,timeout=30) as response:html=response.read().decode()
identifier=re.search(r"data-download-id='([^']+)'",html).group(1)
with client.open("https://kenney.nl/download-link/"+identifier,timeout=30) as response:link=json.load(response)["url"]
with client.open(link,timeout=60) as response:data=response.read()
path=DEST/"kenney_sci-fi-sounds.zip";path.write_bytes(data)
with zipfile.ZipFile(path) as archive:
 assert archive.testzip() is None
 license_text=archive.read("License.txt");assert b"CC0" in license_text
 folder=DEST/"kenney_sfx_source";folder.mkdir(exist_ok=True)
 for name in archive.namelist():
  if name.startswith("Audio/") and name.endswith(".ogg"):(folder/Path(name).name).write_bytes(archive.read(name))
 (ROOT/"licenses/KENNEY_SCI_FI_LICENSE.txt").write_bytes(license_text)
(DEST/"kenney_audio_source.json").write_text(json.dumps({"creator":"Kenney","pack":"Sci-fi Sounds","license":"CC0-1.0","page":page,"acquisition":"Official Continue without donating download action","sha256":hashlib.sha256(data).hexdigest()},indent=2))
print("Verified CC0 Kenney pack:",len(data),"bytes")
