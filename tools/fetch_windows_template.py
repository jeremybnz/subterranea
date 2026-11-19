"""Extract only the Windows release runtime from the official Godot template ZIP."""
import io, json, struct, urllib.request, zipfile, zlib
from pathlib import Path
URL="https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz"
SIZE=1281349702
class Remote(io.RawIOBase):
    def __init__(self): self.position=0; self.cache={}
    def seekable(self): return True
    def readable(self): return True
    def seek(self,offset,whence=0):
        self.position=offset if whence==0 else (self.position+offset if whence==1 else SIZE+offset)
        return self.position
    def tell(self): return self.position
    def read(self,count=-1):
        if count<0: count=SIZE-self.position
        result=fetch(self.position,self.position+count-1)
        self.position+=len(result)
        return result

def fetch(first,last):
    request=urllib.request.Request(URL,headers={"User-Agent":"Subterranea-build","Range":f"bytes={first}-{last}"})
    with urllib.request.urlopen(request,timeout=45) as response:
        if response.status!=206: raise RuntimeError("Server did not support ranged template download")
        return response.read()

remote=Remote()
with zipfile.ZipFile(remote) as archive:
    info=next(item for item in archive.infolist() if item.filename.endswith("/windows_release_x86_64.exe"))
header=fetch(info.header_offset,info.header_offset+29)
name_size,extra_size=struct.unpack_from("<HH",header,26)
start=info.header_offset+30+name_size+extra_size
compressed=fetch(start,start+info.compress_size-1)
result=zlib.decompress(compressed,-15) if info.compress_type==zipfile.ZIP_DEFLATED else compressed
assert len(result)==info.file_size and zlib.crc32(result)==info.CRC
folder=Path(__file__).resolve().parent/"runtime"
folder.mkdir(exist_ok=True)
(folder/"windows_release_x86_64.exe").write_bytes(result)
(folder/"source.json").write_text(json.dumps({"url":URL,"member":info.filename,"bytes":len(result),"crc32":info.CRC},indent=2),encoding="utf-8")
print(f"Windows release runtime ready: {len(result):,} bytes; downloaded only its ZIP member.",flush=True)
