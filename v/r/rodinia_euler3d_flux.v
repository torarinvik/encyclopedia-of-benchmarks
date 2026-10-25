// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
module rodinia_euler3d_flux

import math

const input_count = 41
const gamma32 = f32(1.4)
const smoothing32 = f32(0.2)

struct Flow {
mut:
	density f32
	momentum [3]f32
	energy f32
	pressure f32
	velocity [3]f32
	speed2 f32
	speed f32
	sound f32
	momentum_flux [3][3]f32
	energy_flux [3]f32
}

@[inline]
fn add32(a f32,b f32) f32{return a+b}
@[inline]
fn sub32(a f32,b f32) f32{return a-b}
@[inline]
fn mul32(a f32,b f32) f32{return a*b}
@[inline]
fn div32(a f32,b f32) f32{return a/b}
fn finite32(x f32) bool{return !math.is_nan(f64(x))&&!math.is_inf(f64(x))}
fn sqrt32(x f32) f32{return f32(math.sqrt(f64(x)))}

fn read_state(v &i64) ?Flow {
	mut raw := [5]f32{}
	for i in 0 .. 5 {
		if v[i]<0||u64(v[i])>u64(0xffff_ffff){return none}
		bits:=u32(v[i]);if (bits&u32(0x7f800000))==u32(0x7f800000){return none}
		raw[i]=math.f32_from_bits(bits)
	}
	if raw[0]<f32(0.5)||raw[0]>f32(2.0)||math.abs(f64(raw[1]))>1.0||math.abs(f64(raw[2]))>1.0||math.abs(f64(raw[3]))>1.0||raw[4]<f32(1.0)||raw[4]>f32(5.0){return none}
	mut f:=Flow{density:raw[0],momentum:[3]f32{raw[1],raw[2],raw[3]},energy:raw[4]}
	for d in 0 .. 3{f.velocity[d]=div32(f.momentum[d],f.density)}
	f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]))
	kinetic:=mul32(mul32(f32(0.5),f.density),f.speed2)
	f.pressure=mul32(sub32(gamma32,f32(1.0)),sub32(f.energy,kinetic));if !finite32(f.pressure)||f.pressure<=0{return none}
	f.speed=sqrt32(f.speed2);f.sound=sqrt32(div32(mul32(gamma32,f.pressure),f.density));de_p:=add32(f.energy,f.pressure)
	f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2])
	f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2])
	f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
	for d in 0 .. 3{f.energy_flux[d]=mul32(f.velocity[d],de_p)}
	if !finite32(f.speed)||!finite32(f.sound){return none};return f
}

fn farfield() Flow {
	mut f:=Flow{density:f32(1.4),pressure:f32(1.0)}
	f.sound=sqrt32(div32(mul32(gamma32,f.pressure),f.density));f.speed=mul32(f32(1.2),f.sound);f.velocity=[3]f32{f.speed,0,0}
	for d in 0 .. 3{f.momentum[d]=mul32(f.density,f.velocity[d])}
	f.energy=add32(mul32(f.density,mul32(f32(0.5),mul32(f.speed,f.speed))),div32(f.pressure,sub32(gamma32,f32(1.0))))
	f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));de_p:=add32(f.energy,f.pressure)
	f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2])
	f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2])
	f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure)
	for d in 0 .. 3{f.energy_flux[d]=mul32(f.velocity[d],de_p)}
	return f
}
fn round_away(x f32) i64{scaled:=f64(x)*1000.0;if scaled<0{return -i64(math.floor(-scaled+0.5))};return i64(math.floor(scaled+0.5))}

@[export: 'rodinia_euler3d_flux']
pub fn rodinia_euler3d_flux(values &i64,length usize)i64{
	unsafe{
		if values==nil||length!=input_count{return -1}
		center_opt:=read_state(values);if center_opt==none{return -1};center:=center_opt or {return -1}
		mut kinds:=[4]i64{};mut normals:=[4][3]f32{};mut neighbors:=[4]Flow{}
		for face in 0 .. 4{
			at:=5+face*9;kinds[face]=values[at];if kinds[face]< -2||kinds[face]>0{return -1}
			for d in 0 .. 3{raw:=values[at+1+d];if raw<0||u64(raw)>u64(0xffff_ffff){return -1};bits:=u32(raw);if (bits&u32(0x7f800000))==u32(0x7f800000){return -1};normals[face][d]=math.f32_from_bits(bits);if !finite32(normals[face][d])||math.abs(f64(normals[face][d]))>1.0{return -1}}
			neighbor_opt:=read_state(&values[at+4]);if neighbor_opt==none{return -1};neighbors[face]=neighbor_opt or {return -1}
		}
		far:=farfield();mut fd:=f32(0);mut fe:=f32(0);mut fm:=[3]f32{}
		for face in 0 .. 4{
			nx,ny,nz:=normals[face][0],normals[face][1],normals[face][2]
			normal_len:=sqrt32(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)))
			if kinds[face]==0{
				nb:=neighbors[face];mut factor:=mul32(mul32(mul32(-normal_len,smoothing32),f32(0.5)),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound))
				fd=add32(fd,mul32(factor,sub32(center.density,nb.density)));fe=add32(fe,mul32(factor,sub32(center.energy,nb.energy)))
				for c in 0 .. 3{fm[c]=add32(fm[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])))}
				ns:=[3]f32{nx,ny,nz};for axis in 0 .. 3{factor=mul32(f32(0.5),ns[axis]);fd=add32(fd,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));fe=add32(fe,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for c in 0 .. 3{fm[c]=add32(fm[c],mul32(factor,add32(nb.momentum_flux[axis][c],center.momentum_flux[axis][c])))}}
			}else if kinds[face]== -1{fm[0]=add32(fm[0],mul32(nx,center.pressure));fm[1]=add32(fm[1],mul32(ny,center.pressure));fm[2]=add32(fm[2],mul32(nz,center.pressure))
			}else{ns:=[3]f32{nx,ny,nz};for axis in 0 .. 3{factor:=mul32(f32(0.5),ns[axis]);fd=add32(fd,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));fe=add32(fe,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for c in 0 .. 3{fm[c]=add32(fm[c],mul32(factor,add32(far.momentum_flux[axis][c],center.momentum_flux[axis][c])))}}}
		}
		components:=[5]f32{fd,fm[0],fm[1],fm[2],fe};mut checksum:=i64(0)
		for i in 0 .. 5{if !finite32(components[i]){return -1};checksum+=i64(i+1)*round_away(components[i])}
		return checksum
	}
}
