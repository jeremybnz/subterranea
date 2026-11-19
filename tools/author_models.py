"""Original hand-shaped flight models, authored as reusable glTF 2.0 binary assets."""
import json, math, struct
from collections import defaultdict
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]/"assets"/"models"
ROOT.mkdir(parents=True,exist_ok=True)
def rgb(hex_value):
    # glTF color factors are linear; authored hexadecimal colors are sRGB.
    values=[int(hex_value[i:i+2],16)/255 for i in (0,2,4)]
    return [v/12.92 if v<=.04045 else ((v+.055)/1.055)**2.4 for v in values]
MATERIALS=[]
for name,color,metal,rough,glow in [("Titanium","8197a1",.72,.32,False),("Armor","273b4a",.65,.39,False),("Ceramic","d2d9d6",.25,.38,False),("Canopy","123e52",.72,.12,False),("Cyan","6ef0df",.1,.25,True),("Amber","ffad5b",.1,.3,True),("Red","ef765b",.1,.3,True),("Violet","c0a0ff",.1,.3,True),("Black","0b141d",.3,.6,False),("Machined","a0a8ad",.9,.26,False),("Rubber","18202a",.05,.8,False),("Gold","c2a777",.8,.32,False)]:
    m={"name":name,"pbrMetallicRoughness":{"baseColorFactor":rgb(color)+[1],"metallicFactor":metal,"roughnessFactor":rough}}
    if glow:
        m["pbrMetallicRoughness"]["baseColorFactor"]=[v*.02 for v in rgb(color)]+[1]
        m.update({"emissiveFactor":rgb(color),"extensions":{"KHR_materials_emissive_strength":{"emissiveStrength":1.0}}})
    MATERIALS.append(m)

class Model:
    def __init__(self): self.parts=defaultdict(list)
    def poly(self,vertices,faces,material):
        center=[sum(v[k] for v in vertices)/len(vertices) for k in range(3)]
        for face in faces:
            for index in range(1,len(face)-1):
                a,b,c=[vertices[face[i]] for i in (0,index,index+1)]
                u=[b[i]-a[i] for i in range(3)]; v=[c[i]-a[i] for i in range(3)]
                n=[u[1]*v[2]-u[2]*v[1],u[2]*v[0]-u[0]*v[2],u[0]*v[1]-u[1]*v[0]]
                point=[(a[i]+b[i]+c[i])/3-center[i] for i in range(3)]
                if sum(n[i]*point[i] for i in range(3))<0: b,c=c,b; n=[-x for x in n]
                length=math.sqrt(sum(x*x for x in n)) or 1
                normal=[x/length for x in n]
                for vertex in [a,b,c]: self.parts[material].append((vertex,normal))
    def loft(self,stations,material=0,offset=(0,0,0)):
        vertices=[]
        for z,w,h in stations:
            for x,y in [(-w,-h*.55),(-w*.65,-h),(w*.65,-h),(w,-h*.55),(w,h*.55),(w*.65,h),(-w*.65,h),(-w,h*.55)]:
                vertices.append((x+offset[0],y+offset[1],z+offset[2]))
        faces=[list(range(7,-1,-1))]
        for station in range(len(stations)-1):
            for i in range(8): faces.append([station*8+i,station*8+(i+1)%8,(station+1)*8+(i+1)%8,(station+1)*8+i])
        faces.append(list(range((len(stations)-1)*8,len(stations)*8)))
        self.poly(vertices,faces,material)
    def bevel(self,pos,size,material=0,edge=.06):
        x,y,z=pos; w,h,d=[v/2 for v in size]; e=min(edge,w*.4,h*.4,d*.4)
        self.loft([(-d,w-e,h-e),(-d+e,w,h),(d-e,w,h),(d,w-e,h-e)],material,pos)
    def plate(self,points,y,thickness,material=0):
        n=len(points); center=[sum(p[i] for p in points)/n for i in range(2)]
        v=[]
        for height,inset in [(-thickness/2,.93),(-thickness*.15,1),(thickness*.15,1),(thickness/2,.93)]:
            for x,z in points: v.append((center[0]+(x-center[0])*inset,y+height,center[1]+(z-center[1])*inset))
        faces=[list(range(n-1,-1,-1)),list(range(n*3,n*4))]
        for ring in range(3):
            for i in range(n): faces.append([ring*n+i,ring*n+(i+1)%n,(ring+1)*n+(i+1)%n,(ring+1)*n+i])
        self.poly(v,faces,material)
    def ring(self,pos,outer,inner,depth,material=9,sides=24,axis="z"):
        v=[]
        for z,r in [(-depth/2,outer),(depth/2,outer),(-depth/2,inner),(depth/2,inner)]:
            for i in range(sides):
                x,y=math.cos(i*math.tau/sides)*r,math.sin(i*math.tau/sides)*r
                xyz=(x,y,z) if axis=="z" else ((x,z,y) if axis=="y" else (z,x,y))
                v.append(tuple(xyz[k]+pos[k] for k in range(3)))
        faces=[]
        for i in range(sides):
            j=(i+1)%sides
            faces.extend([[i,j,sides+j,sides+i],[2*sides+i,3*sides+i,3*sides+j,2*sides+j],[i,2*sides+i,2*sides+j,j],[sides+i,sides+j,3*sides+j,3*sides+i]])
        # Annular interior normals point into the bore, not away from the centroid.
        for face_index,face in enumerate(faces):
            before=len(self.parts[material]); self.poly(v,[face],material)
            if face_index%4==1:
                triangles=self.parts[material][before:]; del self.parts[material][before:]
                for j in range(0,len(triangles),3):
                    for vertex,normal in [triangles[j],triangles[j+2],triangles[j+1]]: self.parts[material].append((vertex,[-x for x in normal]))
    def engine(self,x,y,z,r=.3,color=4):
        z+=.32 # Recessed core must sit beyond the sealed nacelle end cap.
        self.ring((x,y,z-.18),r*1.12,r*.72,.45,8,24)
        self.ring((x,y,z),r*1.16,r*.78,.15,9)
        self.ring((x,y,z-.13),r*.8,r*.63,.09,11)
        self.tube((x,y,z-.22),r*.68,.02,8,24)
        self.ring((x,y,z-.18),r*.55,r*.36,.025,color)
        self.tube((x,y,z-.19),r*.23,.025,color,20)
        for i in range(8):
            a=i*math.tau/8; self.bevel((x+math.cos(a)*r*1.04,y+math.sin(a)*r*1.04,z-.04),(r*.18,r*.18,.24),1,.015)
    def vent(self,pos,count=5,width=.36,step=.1):
        x,y,z=pos
        self.bevel((x,y,z),(width+.12,.06,count*step+.1),8,.02)
        for i in range(count): self.box((x,y+.036,z+(i-(count-1)/2)*step),(width,.025,.028),9)
    def gun(self,x,y,z,r=.1,length=.7,color=6):
        self.tube((x,y,z+length*.2),r*1.65,length*.55,1,12)
        self.tube((x,y,z-length*.2),r,length*.65,9,16)
        self.ring((x,y,z-length*.52),r*1.25,r*.72,.08,8,16)
        self.tube((x,y,z-length*.49),r*.65,.015,color,16)
    def wing(self,points,y,thickness,material=0):
        vertices=[(x,y+t,z) for t in [-thickness/2,thickness/2] for x,z in points]
        count=len(points)
        faces=[list(range(count-1,-1,-1)),list(range(count,count*2))]
        for i in range(count): faces.append([i,(i+1)%count,(i+1)%count+count,i+count])
        self.poly(vertices,faces,material)
    def box(self,pos,size,material=0):
        x,y,z=pos; a,b,c=[v/2 for v in size]
        self.poly([(x+i*a,y+j*b,z+k*c) for i,j,k in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]],[[0,1,2,3],[4,7,6,5],[0,4,5,1],[3,2,6,7],[0,3,7,4],[1,5,6,2]],material)
    def tube(self,pos,radius,length,material=0,sides=12):
        x,y,z=pos
        vertices=[(x+math.cos(i*math.tau/sides)*radius,y+math.sin(i*math.tau/sides)*radius,z+t) for t in [-length/2,length/2] for i in range(sides)]
        faces=[list(range(sides-1,-1,-1)),list(range(sides,sides*2))]
        for i in range(sides): faces.append([i,(i+1)%sides,(i+1)%sides+sides,i+sides])
        self.poly(vertices,faces,material)
    def save(self,name):
        document={"asset":{"version":"2.0","generator":"Subterranea original mesh authoring"},"extensionsUsed":["KHR_materials_emissive_strength"],"scene":0,"scenes":[{"nodes":[0]}],"nodes":[{"name":name,"mesh":0}],"materials":MATERIALS,"meshes":[{"name":name,"primitives":[]}],"bufferViews":[],"accessors":[],"buffers":[{"byteLength":0}]}
        binary=bytearray()
        def accessor(values,kind):
            start=len(binary)
            flat=[component for value in values for component in value]
            binary.extend(struct.pack("<"+"f"*len(flat),*flat))
            view=len(document["bufferViews"])
            document["bufferViews"].append({"buffer":0,"byteOffset":start,"byteLength":len(flat)*4,"target":34962})
            entry={"bufferView":view,"componentType":5126,"count":len(values),"type":kind}
            if kind=="VEC3":
                entry["min"]=[min(v[k] for v in values) for k in range(3)]
                entry["max"]=[max(v[k] for v in values) for k in range(3)]
            document["accessors"].append(entry)
            return len(document["accessors"])-1
        for material,vertices in self.parts.items():
            pos=accessor([v[0] for v in vertices],"VEC3")
            normal=accessor([v[1] for v in vertices],"VEC3")
            document["meshes"][0]["primitives"].append({"attributes":{"POSITION":pos,"NORMAL":normal},"material":material,"mode":4})
        document["buffers"][0]["byteLength"]=len(binary)
        encoded=json.dumps(document,separators=(",",":")).encode()
        encoded+=b" "*((-len(encoded))%4)
        binary+=b"\0"*((-len(binary))%4)
        total=12+8+len(encoded)+8+len(binary)
        output=struct.pack("<4sII",b"glTF",2,total)+struct.pack("<I4s",len(encoded),b"JSON")+encoded+struct.pack("<I4s",len(binary),b"BIN\0")+binary
        (ROOT/(name+".glb")).write_bytes(output)
        print(name,len(output),"bytes")


# Kestrel: recessed canopy, split nose, armored shoulders and twin vector nacelles.
ship=Model()
ship.loft([(-2.62,.15,.08),(-2.18,.4,.19),(-.9,.73,.4),(.35,.94,.46),(1.55,.68,.29),(1.83,.42,.22)],1)
ship.loft([(-2.48,.12,.06),(-1.45,.42,.16),(-.65,.55,.19)],0,(0,.23,0))
ship.loft([(-1.44,.25,.09),(-.73,.47,.27),(.27,.4,.23),(.57,.23,.07)],8,(0,.43,0))
ship.loft([(-1.32,.21,.07),(-.68,.405,.23),(.22,.345,.19),(.46,.2,.07)],3,(0,.475,0))
ship.bevel((0,.718,-.2),(.045,.035,.85),9,.01)
ship.bevel((0,.72,.24),(.62,.04,.05),9,.01)
ship.bevel((0,-.39,-.36),(.6,.13,1.5),8)
for side in [-1,1]:
    def pts(items): return [(side*x,z) for x,z in items]
    ship.plate(pts([(.62,-.75),(1.48,-.94),(2.48,.04),(3.03,1.22),(2.63,1.52),(1.07,1.0)]),-.05,.28,1)
    ship.plate(pts([(.83,-.58),(1.47,-.72),(2.11,.05),(1.8,.76),(.99,.61)]),.13,.13,0)
    ship.plate(pts([(2.07,.16),(2.72,.89),(2.77,1.18),(2.5,1.27),(1.95,.69)]),.13,.12,2)
    ship.plate(pts([(1.02,.72),(1.72,.85),(2.4,1.38),(2.06,1.39)]),.105,.05,11)
    ship.plate(pts([(1.2,-.5),(1.3,-.5),(1.89,.16),(1.82,.21)]),.21,.018,4)
    ship.loft([(-1.34,.14,.16),(-1.03,.31,.29),(.66,.36,.36),(1.64,.29,.28),(1.86,.25,.25)],0,(side*1.47,-.16,0))
    ship.bevel((side*1.47,.19,.12),(.39,.11,.92),1)
    ship.vent((side*1.47,.26,.24),6,.25,.11)
    ship.bevel((side*1.8,-.11,.4),(.1,.25,.85),1)
    ship.bevel((side*1.85,-.11,.4),(.025,.07,.48),4,.01)
    ship.engine(side*1.47,-.16,1.92,.255,4)
    ship.gun(side*1.47,-.21,-1.62,.095,.95,4)
    ship.plate(pts([(.62,-.12),(.93,.04),(.81,.82),(.53,.75)]),.43,.14,0)
    ship.vent((side*.72,.53,.34),4,.13,.09)
    ship.bevel((side*.72,.48,.88),(.14,.07,.29),5,.02)
    # Outboard maneuvering jets face sideways; these remain visible from above.
    ship.ring((side*2.65,-.04,.93),.17,.11,.11,9,16,"x")
    ship.ring((side*2.68,-.04,.93),.105,.07,.02,4,16,"x")
    ship.ring((side*1.47,.29,-.57),.14,.095,.06,8,16,"y")
    ship.ring((side*1.47,.32,-.57),.085,.06,.02,4,16,"y")
    for z in [-.35,.06,.48]:
        ship.bevel((side*.98,.17,z),(.08,.045,.07),9,.01)
    # Identification bars remain pale through all paint schemes.
    for j in range(3): ship.box((side*(2.16+j*.12),.208,.56+j*.12),(.06,.012,.21),0)
ship.save("kestrel")

# Scout: pointed sensor head with open swept outriggers and tiny turbine pods.
scout=Model()
scout.loft([(-1.16,.1,.07),(-.58,.42,.24),(.15,.52,.3),(.66,.28,.18)],1)
scout.loft([(-.98,.1,.06),(-.42,.3,.12),(.28,.31,.1)],0,(0,.22,0))
scout.tube((0,0,-1.09),.2,.11,8,20); scout.ring((0,0,-1.16),.18,.105,.06,9,20); scout.tube((0,0,-1.18),.105,.025,6,20)
for side in [-1,1]:
    scout.plate([(side*x,z) for x,z in [(.32,-.37),(.64,-.68),(1.48,.22),(1.34,.67),(.83,.39),(.4,.19)]],-.04,.13,1)
    scout.plate([(side*x,z) for x,z in [(.56,-.37),(.64,-.43),(1.25,.23),(1.16,.31)]],.045,.035,0)
    scout.loft([(-.13,.14,.13),(.38,.2,.19),(.76,.16,.15)],0,(side*1.05,-.04,0))
    scout.engine(side*1.05,-.04,.84,.145,6)
    scout.gun(side*.45,-.18,-.43,.065,.48,6)
    scout.bevel((side*1.26,.13,.25),(.07,.08,.28),6,.02)
    scout.vent((side*.3,.3,.13),3,.12,.08)
scout.save("scout")

# Striker: aggressive, narrow double-boom gunship with prominent chin guns.
striker=Model()
striker.loft([(-.96,.17,.18),(-.32,.42,.33),(.55,.36,.27),(.85,.23,.2)],1)
striker.loft([(-.78,.16,.07),(-.25,.3,.13),(.48,.25,.1)],0,(0,.29,0))
striker.bevel((0,.1,-.98),(.4,.19,.12),8,.03)
striker.bevel((0,.1,-1.055),(.27,.065,.03),7,.01)
for side in [-1,1]:
    striker.plate([(side*x,z) for x,z in [(.25,-.35),(.8,-.82),(1.27,-.23),(1.46,.77),(.67,.53)]],0,.2,1)
    striker.loft([(-1.05,.17,.2),(-.72,.25,.28),(.63,.27,.24),(.95,.19,.19)],0,(side*.95,.03,0))
    striker.loft([(-.8,.14,.05),(.32,.18,.08),(.69,.14,.04)],2,(side*.95,.31,0))
    striker.engine(side*.95,.03,1.04,.195,7)
    striker.gun(side*.67,-.3,-.86,.115,1.0,7)
    striker.bevel((side*.68,-.29,-.29),(.34,.3,.55),1)
    striker.vent((side*.95,.4,.18),4,.2,.1)
    striker.bevel((side*1.23,.05,.17),(.06,.16,.51),7,.02)
    striker.ring((side*.94,.33,-.51),.105,.065,.05,8,16,"y")
striker.save("striker")

# Bulwark: broad overlapping frontal armor, compact engine bunker behind it.
def build_bulwark(warden=False):
    m=Model(); color=7 if warden else 5
    m.loft([(-.96,.49,.37),(-.55,.74,.47),(.46,.66,.4),(.85,.41,.29)],1)
    m.bevel((0,.49,.07),(.72,.17,.96),0)
    m.vent((0,.61,.15),5,.46,.11)
    for side in [-1,1]:
        m.plate([(side*x,z) for x,z in [(.3,-.48),(1.04,-.64),(1.53,-.14),(1.3,.65),(.53,.57)]],0,.42,1)
        m.loft([(-1.12,.25,.42),(-.96,.37,.56),(-.52,.36,.54),(-.28,.25,.36)],2,(side*.76,0,0))
        m.loft([(-1.19,.1,.29),(-1.1,.22,.43),(-.98,.21,.42)],0,(side*.76,0,0))
        m.bevel((side*.78,.01,-1.185),(.085,.62,.04),color,.01)
        m.bevel((side*.76,-.51,-.55),(.43,.11,.58),9,.03)
        m.engine(side*.76,0,.89,.245,color)
        m.gun(side*.48,-.41,-.63,.115,.74,color)
        m.ring((side*1.19,.05,.21),.23,.16,.2,9,20,"x")
        for j in range(3): m.bevel((side*1.09,.25,.05+j*.13),(.17,.06,.055),color,.015)
    m.tube((0,0,-1.04),.27,.15,8,24); m.ring((0,0,-1.14),.23,.14,.09,9); m.tube((0,0,-1.17),.14,.025,color,24)
    if warden:
        # Taller split crown and floating shoulder armor change its silhouette.
        for side in [-1,1]:
            m.loft([(-.7,.18,.23),(.1,.24,.3),(.7,.15,.2)],1,(side*1.31,.51,0))
            m.bevel((side*1.32,.81,.04),(.16,.16,.5),0)
            m.bevel((side*1.33,.9,.04),(.05,.035,.36),7,.01)
            m.ring((side*1.34,.21,-.55),.3,.21,.12,11,24)
            m.ring((side*1.34,.21,-.63),.18,.13,.04,7,24)
        m.bevel((0,.79,.05),(.21,.46,.46),1)
        m.bevel((0,1.04,.05),(.08,.06,.3),7,.02)
    return m
build_bulwark().save("bulwark")
build_bulwark(True).save("warden")

# Overseer: a four-gun command machine with layered segmented wings.
boss=Model()
boss.loft([(-2.62,.72,.52),(-1.7,1.42,1.03),(.35,1.8,1.32),(1.8,1.33,.93),(2.48,.8,.65)],1)
boss.loft([(-2.4,.5,.22),(-.5,.95,.38),(1.6,.64,.22)],0,(0,1.0,0))
boss.vent((0,1.39,.27),7,.93,.2)
boss.loft([(-3.05,.43,.32),(-2.54,.83,.65),(-1.9,.9,.63)],2)
boss.tube((0,0,-3.14),.68,.28,8,32); boss.ring((0,0,-3.3),.69,.48,.18,9,32)
boss.ring((0,0,-3.38),.43,.31,.055,5,32); boss.tube((0,0,-3.34),.29,.03,5,32)
for side in [-1,1]:
    boss.plate([(side*x,z) for x,z in [(1.0,-1.5),(2.5,-1.83),(5.3,-.03),(5.65,1.42),(4.86,2.22),(1.6,1.63)]],0,.7,1)
    boss.plate([(side*x,z) for x,z in [(1.4,-1.23),(2.48,-1.51),(3.41,-.81),(3.1,.68),(1.6,.75)]],.43,.24,0)
    boss.plate([(side*x,z) for x,z in [(3.51,-.61),(4.33,-.12),(4.85,.74),(4.45,1.35),(3.34,.79)]],.4,.23,2)
    boss.plate([(side*x,z) for x,z in [(4.8,.7),(5.28,1.14),(4.77,1.91),(3.9,1.65)]],.36,.18,0)
    boss.loft([(-2.06,.35,.43),(-1.44,.58,.62),(.87,.56,.59),(2.03,.38,.42)],2,(side*3.24,-.09,0))
    boss.bevel((side*3.24,.55,.2),(.55,.21,1.24),1)
    boss.vent((side*3.24,.7,.24),6,.36,.16)
    boss.engine(side*3.24,-.09,2.2,.4,5)
    for y in [-.44,.44]: boss.gun(side*3.24,y,-2.28,.19,1.2,6)
    for j in range(4): boss.bevel((side*(1.65+j*.29),.61,.37+j*.13),(.14,.07,.49),5,.02)
    boss.ring((side*1.67,0,2.1),.38,.26,.3,9,24); boss.engine(side*1.67,0,2.25,.28,5)
    boss.plate([(side*x,z) for x,z in [(1.0,.4),(1.6,.58),(1.51,1.7),(.83,1.37)]],1.21,.22,1)
boss.save("overseer")

# Courier: protected crew capsule, rescue chevrons and twin ducted vector jets.
courier=Model()
courier.loft([(-.94,.26,.17),(-.62,.49,.32),(.54,.46,.33),(.85,.28,.23)],2)
courier.loft([(-.96,.2,.1),(-.68,.36,.13),(-.47,.32,.11)],3,(0,.17,0))
courier.bevel((0,.37,.03),(.28,.08,.79),1,.03)
courier.bevel((0,.42,.03),(.11,.025,.56),4,.01)
courier.bevel((0,.42,.03),(.32,.025,.11),4,.01)
for side in [-1,1]:
    courier.bevel((side*.64,0,.08),(.55,.2,.8),1,.04)
    courier.ring((side*.85,0,.12),.34,.23,.22,9,24)
    courier.ring((side*.85,0,.25),.24,.17,.055,4,24)
    courier.tube((side*.85,0,.13),.12,.02,8,16)
    courier.bevel((side*.45,.12,.29),(.12,.18,.58),0,.025)
    for z in [-.2,.07,.34]: courier.bevel((side*.47,-.13,z),(.09,.12,.055),11,.015)
    courier.engine(side*.29,-.03,.9,.12,4)
courier.save("courier")

# First-person cannon casing; origin matches the animated recoil mount.
gun=Model()
gun.loft([(-.59,.075,.07),(-.46,.135,.11),(.22,.135,.115),(.46,.095,.08)],1)
gun.loft([(-.39,.11,.025),(.12,.105,.035),(.28,.08,.02)],0,(0,.106,0))
gun.bevel((0,-.107,-.03),(.17,.055,.64),8,.02)
gun.vent((0,.145,-.02),5,.12,.075)
for side in [-1,1]:
    gun.bevel((side*.13,0,-.07),(.035,.11,.6),9,.008)
    for z in [-.24,.06,.28]: gun.bevel((side*.145,.015,z),(.016,.065,.028),11,.005)
gun.tube((0,0,-.51),.095,.15,9,20); gun.ring((0,0,-.62),.09,.054,.1,8,20)
gun.tube((0,0,-.59),.049,.012,4,20)
gun.save("cockpit_gun")
