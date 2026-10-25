## Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
import std/math

const InputCount = 41
const Gamma32 = 1.4'f32
const Smoothing32 = 0.2'f32
type Flow = object
  density, energy, pressure, speed2, speed, sound: float32
  momentum, velocity: array[3,float32]
  momentumFlux: array[3,array[3,float32]]
  energyFlux: array[3,float32]

proc add32(a,b:float32):float32 =
  let value:float32=a+b
  value
proc sub32(a,b:float32):float32 =
  let value:float32=a-b
  value
proc mul32(a,b:float32):float32 =
  let value:float32=a*b
  value
proc div32(a,b:float32):float32 =
  let value:float32=a/b
  value
proc finite32(x:float32):bool = classify(float64(x)) notin {fcNan,fcInf,fcNegInf}

proc readState(v:ptr UncheckedArray[int64], f:var Flow):bool =
  var raw:array[5,float32]
  for i in 0..<5:
    if v[i]<0 or uint64(v[i])>0xffff_ffff'u64:return false
    raw[i]=cast[float32](uint32(v[i]))
    if not finite32(raw[i]):return false
  if raw[0]<0.5'f32 or raw[0]>2.0'f32 or abs(raw[1])>1.0'f32 or abs(raw[2])>1.0'f32 or abs(raw[3])>1.0'f32 or raw[4]<1.0'f32 or raw[4]>5.0'f32:return false
  f.density=raw[0];f.momentum=[raw[1],raw[2],raw[3]];f.energy=raw[4]
  for d in 0..<3:f.velocity[d]=div32(f.momentum[d],f.density)
  f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]))
  let kinetic=mul32(mul32(0.5'f32,f.density),f.speed2)
  f.pressure=mul32(sub32(Gamma32,1.0'f32),sub32(f.energy,kinetic))
  if not finite32(f.pressure) or f.pressure<=0.0'f32:return false
  f.speed=sqrt(f.speed2);f.sound=sqrt(div32(mul32(Gamma32,f.pressure),f.density))
  let deP=add32(f.energy,f.pressure)
  f.momentumFlux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentumFlux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentumFlux[0][2]=mul32(f.velocity[0],f.momentum[2])
  f.momentumFlux[1][0]=f.momentumFlux[0][1];f.momentumFlux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentumFlux[1][2]=mul32(f.velocity[1],f.momentum[2])
  f.momentumFlux[2][0]=f.momentumFlux[0][2];f.momentumFlux[2][1]=f.momentumFlux[1][2];f.momentumFlux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
  for d in 0..<3:f.energyFlux[d]=mul32(f.velocity[d],deP)
  finite32(f.speed) and finite32(f.sound)

proc farfield(f:var Flow) =
  f.density=1.4'f32;f.pressure=1.0'f32;f.sound=sqrt(div32(mul32(Gamma32,f.pressure),f.density));f.speed=mul32(1.2'f32,f.sound)
  f.velocity=[f.speed,0.0'f32,0.0'f32]
  for d in 0..<3:f.momentum[d]=mul32(f.density,f.velocity[d])
  f.energy=add32(mul32(f.density,mul32(0.5'f32,mul32(f.speed,f.speed))),div32(f.pressure,sub32(Gamma32,1.0'f32)))
  f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]))
  let deP=add32(f.energy,f.pressure)
  f.momentumFlux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentumFlux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentumFlux[0][2]=mul32(f.velocity[0],f.momentum[2])
  f.momentumFlux[1][0]=f.momentumFlux[0][1];f.momentumFlux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentumFlux[1][2]=mul32(f.velocity[1],f.momentum[2])
  f.momentumFlux[2][0]=f.momentumFlux[0][2];f.momentumFlux[2][1]=f.momentumFlux[1][2];f.momentumFlux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
  for d in 0..<3:f.energyFlux[d]=mul32(f.velocity[d],deP)

proc roundAway(x:float32):int64 =
  let scaled=float64(x)*1000.0
  if scaled<0.0: return -int64(floor(-scaled+0.5))
  int64(floor(scaled+0.5))

proc rodinia_euler3d_flux*(values:ptr UncheckedArray[int64],length:csize_t):int64 {.cdecl,exportc:"rodinia_euler3d_flux".} =
  if values.isNil or length!=csize_t(InputCount):return -1
  var center:Flow
  if not readState(values,center):return -1
  var kinds:array[4,int64]
  var normals:array[4,array[3,float32]]
  var neighbors:array[4,Flow]
  for face in 0..<4:
    let at=5+face*9;kinds[face]=values[at]
    if kinds[face]< -2 or kinds[face]>0:return -1
    for d in 0..<3:
      let raw=values[at+1+d]
      if raw<0 or uint64(raw)>0xffff_ffff'u64:return -1
      normals[face][d]=cast[float32](uint32(raw))
      if not finite32(normals[face][d]) or abs(normals[face][d])>1.0'f32:return -1
    if not readState(cast[ptr UncheckedArray[int64]](addr values[at+4]),neighbors[face]):return -1
  var far:Flow;farfield(far)
  var fluxDensity=0.0'f32;var fluxEnergy=0.0'f32;var fluxMomentum:array[3,float32]
  for face in 0..<4:
    let nx=normals[face][0];let ny=normals[face][1];let nz=normals[face][2]
    let normalLen=sqrt(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)))
    if kinds[face]==0:
      let nb=neighbors[face]
      var factor=mul32(mul32(mul32(-normalLen,Smoothing32),0.5'f32),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound))
      fluxDensity=add32(fluxDensity,mul32(factor,sub32(center.density,nb.density)));fluxEnergy=add32(fluxEnergy,mul32(factor,sub32(center.energy,nb.energy)))
      for c in 0..<3:fluxMomentum[c]=add32(fluxMomentum[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])))
      let ns=[nx,ny,nz]
      for axis in 0..<3:
        factor=mul32(0.5'f32,ns[axis])
        fluxDensity=add32(fluxDensity,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])))
        fluxEnergy=add32(fluxEnergy,mul32(factor,add32(nb.energyFlux[axis],center.energyFlux[axis])))
        for c in 0..<3:fluxMomentum[c]=add32(fluxMomentum[c],mul32(factor,add32(nb.momentumFlux[axis][c],center.momentumFlux[axis][c])))
    elif kinds[face]== -1:
      fluxMomentum[0]=add32(fluxMomentum[0],mul32(nx,center.pressure));fluxMomentum[1]=add32(fluxMomentum[1],mul32(ny,center.pressure));fluxMomentum[2]=add32(fluxMomentum[2],mul32(nz,center.pressure))
    else:
      let ns=[nx,ny,nz]
      for axis in 0..<3:
        let factor=mul32(0.5'f32,ns[axis])
        fluxDensity=add32(fluxDensity,mul32(factor,add32(far.momentum[axis],center.momentum[axis])))
        fluxEnergy=add32(fluxEnergy,mul32(factor,add32(far.energyFlux[axis],center.energyFlux[axis])))
        for c in 0..<3:fluxMomentum[c]=add32(fluxMomentum[c],mul32(factor,add32(far.momentumFlux[axis][c],center.momentumFlux[axis][c])))
  let components=[fluxDensity,fluxMomentum[0],fluxMomentum[1],fluxMomentum[2],fluxEnergy]
  var checksum=0'i64
  for i in 0..<5:
    if not finite32(components[i]):return -1
    checksum+=int64(i+1)*roundAway(components[i])
  checksum
