# Independent bounded FreeBench/distray profile.
# Ray-tracer attribution: Marcus Geelnard; benchmarkification: Peter Rundberg.
# The pinned upstream source contains no explicit license grant.
import std/math

const Width = 640
const Height = 480
const Epsilon = 1.0e-5
const MaxT = 1.0e5
const MaxRec = 6
const DistLevels = 3

type
  Vec3 = object
    x, y, z: float64
  Texture = object
    color: Vec3
    diffuse, reflect, roughness: float64
  Sphere = object
    center: Vec3
    radius: float64
    texture: Texture
  Hit = object
    t: float64
    point, normal: Vec3
    texture: Texture
  Context = object
    distribution: int
    state: uint64

const Spheres = [
  Sphere(center: Vec3(x:0.0,y:4.0,z:1.0),radius:1.0,texture:Texture(color:Vec3(x:1.0,y:0.4,z:0.0),diffuse:0.4,reflect:0.8,roughness:0.02)),
  Sphere(center: Vec3(x:-1.0,y:3.0,z:0.4),radius:0.4,texture:Texture(color:Vec3(x:0.5,y:0.3,z:1.0),diffuse:0.5,reflect:0.9,roughness:0.01)),
  Sphere(center: Vec3(x:-0.3,y:1.0,z:0.4),radius:0.4,texture:Texture(color:Vec3(x:0.1,y:0.95,z:0.2),diffuse:0.6,reflect:0.8,roughness:0.01)),
  Sphere(center: Vec3(x:1.0,y:2.0,z:0.4),radius:0.4,texture:Texture(color:Vec3(x:0.86,y:0.83,z:0.0),diffuse:0.7,reflect:0.6,roughness:0.01))
]
const Ground = [
  Texture(color:Vec3(x:0.0,y:0.1,z:0.5),diffuse:0.8,reflect:0.44,roughness:0.02),
  Texture(color:Vec3(x:0.6,y:1.0,z:0.5),diffuse:0.8,reflect:0.44,roughness:0.01)
]
const Light = Vec3(x:-3.0,y:1.0,z:5.0)
const Camera = Vec3(x:1.5,y:-1.4,z:1.2)
const CameraRight = Vec3(x:3.0,y:1.0,z:0.0)
const CameraDir = Vec3(x:-1.0,y:3.0,z:0.0)
const CameraUp = Vec3(x:0.0,y:0.0,z:2.3717)
const SkyHorizon = Vec3(x:0.5,y:0.3,z:0.7)
const SkyZenith = Vec3(x:0.0,y:0.0,z:0.2)

proc add(a, b: Vec3): Vec3 = Vec3(x:a.x+b.x,y:a.y+b.y,z:a.z+b.z)
proc sub(a, b: Vec3): Vec3 = Vec3(x:a.x-b.x,y:a.y-b.y,z:a.z-b.z)
proc mul(a: Vec3, s: float64): Vec3 = Vec3(x:a.x*s,y:a.y*s,z:a.z*s)
proc dot(a, b: Vec3): float64 = a.x*b.x+a.y*b.y+a.z*b.z
proc vlen(a: Vec3): float64 = sqrt(dot(a,a))

proc jitter(ctx: var Context): float64 =
  ctx.state = (1103515245'u64*ctx.state+12345'u64) and 0x7fffffff'u64
  1.0-float64(ctx.state)/float64(0x3fffffff'u64)

proc distributed(ctx: var Context, n: Vec3, sa, sb: float64): Vec3 =
  var a, b: Vec3
  if abs(n.z)>Epsilon:
    a=Vec3(x:n.y*n.z,y:-n.x*n.z,z:0.0)
    b=Vec3(x:a.y*n.z,y:-a.x*n.z,z:a.x*n.y-a.y*n.x)
  else:
    a=Vec3(x:n.y,y:-n.x,z:0.0)
    b=Vec3(x:0.0,y:0.0,z:1.0)
  let nl=vlen(n)
  a=mul(a,sa*(nl/vlen(a))*jitter(ctx))
  b=mul(b,sb*(nl/vlen(b))*jitter(ctx))
  add(a,b)

proc reflect(d, n: Vec3): Vec3 = add(d,mul(n,-2.0*dot(d,n)/dot(n,n)))

proc intersect(origin, d: Vec3): Hit =
  result=Hit(t:-1.0,point:Vec3(x:0.0,y:0.0,z:0.0),normal:Vec3(x:0.0,y:0.0,z:0.0),texture:Ground[0])
  if abs(d.z)>Epsilon:
    let t= -origin.z/d.z
    if t>Epsilon and t<MaxT:
      result.t=t
      result.point=add(origin,mul(d,t))
      result.normal=Vec3(x:0.0,y:0.0,z:1.0)
      let tile=((result.point.x+50000.0).int+(result.point.y+50000.0).int) and 1
      result.texture=Ground[tile]
  for sphere in Spheres:
    let rel=sub(sphere.center,origin)
    let inv=1.0/dot(d,d)
    let b=dot(rel,d)*inv
    let c=(sphere.radius*sphere.radius-dot(rel,rel))*inv
    let disc=c+b*b
    if disc>0.0:
      let root=sqrt(disc)
      var t=b-root
      if t<Epsilon: t=b+root
      if t>Epsilon and (t<result.t or result.t<0.0):
        result.t=t
        let local=mul(d,t)
        result.normal=sub(local,rel)
        result.point=add(local,origin)
        result.texture=sphere.texture

proc trace(ctx: var Context, origin,d: Vec3, recursion:int): Vec3 =
  if recursion<=0: return Vec3(x:0.0,y:0.0,z:0.0)
  let usedist=(MaxRec-recursion)<DistLevels
  let hit=intersect(origin,d)
  if hit.t>Epsilon:
    let ld=sub(Light,hit.point)
    let cosine=dot(ld,hit.normal)
    var amount=0.0
    if cosine>0.0:
      var visible=0
      if usedist:
        let rs=0.4/vlen(ld)
        for _ in 0..<ctx.distribution:
          let off=distributed(ctx,ld,rs,rs)
          let shadow=intersect(hit.point,add(ld,off))
          if shadow.t<Epsilon or shadow.t>1.0: inc visible
      else:
        let shadow=intersect(hit.point,ld)
        if shadow.t<Epsilon or shadow.t>1.0: visible=ctx.distribution
      if visible>0:
        let norm=dot(hit.normal,hit.normal)*dot(ld,ld)
        amount=cosine/sqrt(norm)*hit.texture.diffuse*visible.float64/ctx.distribution.float64
    result=mul(hit.texture.color,0.3+amount)
    if hit.texture.reflect>Epsilon:
      let rd=reflect(d,hit.normal)
      var rc=Vec3(x:0.0,y:0.0,z:0.0)
      if usedist and hit.texture.roughness>Epsilon:
        for _ in 0..<ctx.distribution:
          let off=distributed(ctx,rd,hit.texture.roughness,hit.texture.roughness)
          rc=add(rc,trace(ctx,hit.point,add(rd,off),recursion-1))
        rc=mul(rc,1.0/ctx.distribution.float64)
      else: rc=trace(ctx,hit.point,rd,recursion-1)
      result=add(result,mul(rc,hit.texture.reflect))
  else:
    let horizontal=sqrt(d.x*d.x+d.y*d.y)
    let blend=if horizontal>0.0: arctan(abs(d.z)/horizontal)*0.63661977 else: 1.0
    result=add(mul(SkyZenith,blend),mul(SkyHorizon,1.0-blend))
  result.x=min(result.x,1.0)
  result.y=min(result.y,1.0)
  result.z=min(result.z,1.0)

proc freebench_distray*(input: ptr UncheckedArray[int64], inputLength: csize_t,
    output: ptr UncheckedArray[uint8], outputCapacity: csize_t): int64 {.cdecl, exportc:"freebench_distray".} =
  if input==nil or inputLength!=3: return -1
  let distrib=input[0]
  let x=input[1]
  let y=input[2]
  if distrib<1 or distrib>5 or x<0 or x>=Width or y<0 or y>=Height: return -1
  if output==nil or outputCapacity<3: return -2
  var ctx=Context(distribution:distrib.int,state:0x52462467'u64)
  let sx=(x.float64-Width.float64/2.0)/Width.float64
  let sz=(Height.float64/2.0-y.float64)/Height.float64
  let d=Vec3(x:CameraRight.x*sx+CameraDir.x+CameraUp.x*sz,
             y:CameraRight.y*sx+CameraDir.y+CameraUp.y*sz,
             z:CameraRight.z*sx+CameraDir.z+CameraUp.z*sz)
  var color=Vec3(x:0.0,y:0.0,z:0.0)
  for _ in 0..<ctx.distribution:
    let off=distributed(ctx,d,0.5/Width.float64,0.5/Height.float64)
    color=add(color,trace(ctx,Camera,add(d,off),MaxRec))
  color=mul(color,1.0/ctx.distribution.float64)
  output[0]=uint8(int(color.x*255.0) and 0xfe)
  output[1]=uint8(int(color.y*255.0) and 0xfe)
  output[2]=uint8(int(color.z*255.0) and 0xfe)
  3
