"""Partition original hull triangles into six reusable armor/engine breakup chunks."""
from pathlib import Path
from collections import defaultdict
import json,struct
ROOT=Path(__file__).resolve().parents[1]/"assets/models"
def build(path):
 data=path.read_bytes(); n=struct.unpack_from("<I",data,12)[0]; source=json.loads(data[20:20+n]); binary=data[28+n:]
 def values(index):
  a=source["accessors"][index]; v=source["bufferViews"][a["bufferView"]]; start=v.get("byteOffset",0)+a.get("byteOffset",0)
  return [struct.unpack_from("<3f",binary,start+i*v.get("byteStride",12)) for i in range(a["count"])]
 entries=[]
 for primitive in source["meshes"][0]["primitives"]:
  vertices=values(primitive["attributes"]["POSITION"]); normals=values(primitive["attributes"]["NORMAL"])
  entries.append((primitive["material"],vertices,normals))
 extent=max(abs(v[0]) for _,vertices,_ in entries for v in vertices); cut=extent*.26
 groups=defaultdict(lambda:defaultdict(list))
 for material,vertices,normals in entries:
  for i in range(0,len(vertices),3):
   center=[sum(v[k] for v in vertices[i:i+3])/3 for k in range(3)]
   region="port" if center[0]<-cut else ("starboard" if center[0]>cut else "core")
   region+="_engine" if center[2]>.3 else "_armor"
   groups[region][material].extend(zip(vertices[i:i+3],normals[i:i+3]))
 doc={"asset":{"version":"2.0","generator":"Subterranea hull breakup authoring"},"extensionsUsed":source["extensionsUsed"],"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":"Breakup","children":[]}],"materials":source["materials"],"meshes":[],"bufferViews":[],"accessors":[],"buffers":[{"byteLength":0}]}; output=bytearray()
 def accessor(items):
  start=len(output); output.extend(struct.pack("<"+"f"*(len(items)*3),*(c for v in items for c in v)))
  doc["bufferViews"].append({"buffer":0,"byteOffset":start,"byteLength":len(items)*12,"target":34962})
  doc["accessors"].append({"bufferView":len(doc["bufferViews"])-1,"componentType":5126,"count":len(items),"type":"VEC3","min":[min(v[k] for v in items) for k in range(3)],"max":[max(v[k] for v in items) for k in range(3)]})
  return len(doc["accessors"])-1
 for label,materials in sorted(groups.items()):
  points=[v for entries in materials.values() for v,_ in entries]; center=[sum(v[k] for v in points)/len(points) for k in range(3)]
  mesh={"name":label,"primitives":[]}
  for material,items in materials.items():
   pos=accessor([tuple(v[k]-center[k] for k in range(3)) for v,_ in items]); normal=accessor([n for _,n in items])
   mesh["primitives"].append({"attributes":{"POSITION":pos,"NORMAL":normal},"material":material,"mode":4})
  doc["nodes"][0]["children"].append(len(doc["nodes"])); doc["nodes"].append({"name":label,"mesh":len(doc["meshes"]),"translation":center});doc["meshes"].append(mesh)
 doc["buffers"][0]["byteLength"]=len(output); encoded=json.dumps(doc,separators=(",",":")).encode(); encoded+=b" "*((-len(encoded))%4); output+=b"\0"*((-len(output))%4)
 total=28+len(encoded)+len(output); final=struct.pack("<4sII",b"glTF",2,total)+struct.pack("<I4s",len(encoded),b"JSON")+encoded+struct.pack("<I4s",len(output),b"BIN\0")+output
 dest=path.with_stem(path.stem+"_debris");dest.write_bytes(final);print(dest.name,len(groups),"chunks",len(final),"bytes")
if __name__=="__main__":
 for name in ["kestrel","scout","striker","bulwark","warden","overseer","courier"]:build(ROOT/(name+".glb"))
