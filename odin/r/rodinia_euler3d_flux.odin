// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
package rodinia_euler3d_flux

import "core:c"
import "core:math"

INPUTS :: 41
GAMMA :: f32(1.4)
SMOOTHING :: f32(0.2)
Flow :: struct {
    density, energy, pressure, speed2, speed, sound: f32,
    momentum, velocity: [3]f32,
    mom_flux: [3][3]f32,
    energy_flux: [3]f32,
}
add32 :: proc "contextless" (a,b:f32)->f32{return a+b}
sub32 :: proc "contextless" (a,b:f32)->f32{return a-b}
mul32 :: proc "contextless" (a,b:f32)->f32{return a*b}
div32 :: proc "contextless" (a,b:f32)->f32{return a/b}
sqrt32 :: proc "contextless" (x:f32)->f32{return f32(math.sqrt_f64(f64(x)))}
from_bits :: proc "contextless" (bits:u32)->f32{return transmute(f32)bits}

read_state :: proc "contextless" (v:[^]i64,start:usize,f:^Flow)->bool {
    raw:[5]f32
    for i:usize=0;i<5;i+=1 {
        if v[start+i]<0 || v[start+i]>4294967295 do return false
        bits:=u32(v[start+i]);if ((bits>>23)&255)==255 do return false
        raw[i]=from_bits(bits)
    }
    if raw[0]<0.5 || raw[0]>2.0 || math.abs(f64(raw[1]))>1.0 || math.abs(f64(raw[2]))>1.0 || math.abs(f64(raw[3]))>1.0 || raw[4]<1.0 || raw[4]>5.0 do return false
    f.density=raw[0];f.momentum=[3]f32{raw[1],raw[2],raw[3]};f.energy=raw[4]
    for d:usize=0;d<3;d+=1 { f.velocity[d]=div32(f.momentum[d],f.density) }
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]))
    kinetic:=mul32(mul32(0.5,f.density),f.speed2)
    f.pressure=mul32(sub32(GAMMA,1.0),sub32(f.energy,kinetic))
    if !math.is_finite(f64(f.pressure)) || f.pressure<=0 do return false
    f.speed=sqrt32(f.speed2);f.sound=sqrt32(div32(mul32(GAMMA,f.pressure),f.density));de_p:=add32(f.energy,f.pressure)
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2])
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2])
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
    for d:usize=0;d<3;d+=1 { f.energy_flux[d]=mul32(f.velocity[d],de_p) }
    return math.is_finite(f64(f.speed)) && math.is_finite(f64(f.sound))
}

farfield :: proc "contextless" (f:^Flow) {
    f.density=1.4;f.pressure=1.0;f.sound=sqrt32(div32(mul32(GAMMA,f.pressure),f.density));f.speed=mul32(1.2,f.sound)
    f.velocity=[3]f32{f.speed,0,0};for d:usize=0;d<3;d+=1{f.momentum[d]=mul32(f.density,f.velocity[d])}
    f.energy=add32(mul32(f.density,mul32(0.5,mul32(f.speed,f.speed))),div32(f.pressure,sub32(GAMMA,1.0)))
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));de_p:=add32(f.energy,f.pressure)
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2])
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2])
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
    for d:usize=0;d<3;d+=1{f.energy_flux[d]=mul32(f.velocity[d],de_p)}
}
round_away :: proc "contextless" (x:f32)->i64 {
    scaled:=f64(x)*1000.0
    if scaled<0 do return -i64(math.floor(-scaled+0.5))
    return i64(math.floor(scaled+0.5))
}

@(export)
rodinia_euler3d_flux :: proc "c" (values:[^]i64,length:c.size_t)->i64 {
    if values==nil || length!=c.size_t(INPUTS) do return -1
    center:Flow; if !read_state(values,0,&center) do return -1
    kinds:[4]i64;normals:[4][3]f32;neighbors:[4]Flow
    for face:usize=0;face<4;face+=1 {
        at:=5+face*9;kinds[face]=values[at];if kinds[face] < -2 || kinds[face]>0 do return -1
        for d:usize=0;d<3;d+=1{raw:=values[at+1+d];if raw<0 || raw>4294967295 do return -1;bits:=u32(raw);if ((bits>>23)&255)==255 do return -1;normals[face][d]=from_bits(bits);if math.abs(f64(normals[face][d]))>1.0 do return -1}
        if !read_state(values,at+4,&neighbors[face]) do return -1
    }
    far:Flow;farfield(&far);flux_density:f32=0;flux_energy:f32=0;flux_momentum:[3]f32
    for face:usize=0;face<4;face+=1 {
        nx,ny,nz:=normals[face][0],normals[face][1],normals[face][2]
        normal_len:=sqrt32(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)))
        if kinds[face]==0 {
            nb:=neighbors[face];factor:=mul32(mul32(mul32(-normal_len,SMOOTHING),0.5),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound))
            flux_density=add32(flux_density,mul32(factor,sub32(center.density,nb.density)));flux_energy=add32(flux_energy,mul32(factor,sub32(center.energy,nb.energy)))
            for c:usize=0;c<3;c+=1{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])))}
            ns:=[3]f32{nx,ny,nz}
            for axis:usize=0;axis<3;axis+=1{factor=mul32(0.5,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for c:usize=0;c<3;c+=1{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(nb.mom_flux[axis][c],center.mom_flux[axis][c])))}}
        }else if kinds[face]==-1 {
            flux_momentum[0]=add32(flux_momentum[0],mul32(nx,center.pressure));flux_momentum[1]=add32(flux_momentum[1],mul32(ny,center.pressure));flux_momentum[2]=add32(flux_momentum[2],mul32(nz,center.pressure))
        }else {
            ns:=[3]f32{nx,ny,nz}
            for axis:usize=0;axis<3;axis+=1{factor:=mul32(0.5,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for c:usize=0;c<3;c+=1{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(far.mom_flux[axis][c],center.mom_flux[axis][c])))}}
        }
    }
    result:=[5]f32{flux_density,flux_momentum[0],flux_momentum[1],flux_momentum[2],flux_energy};checksum:i64=0
    for i:usize=0;i<5;i+=1{if !math.is_finite(f64(result[i])) do return -1;checksum+=i64(i+1)*round_away(result[i])}
    return checksum
}
