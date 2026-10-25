// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
const INPUTS: usize = 41;
const GAMMA: f32 = 1.4;
const SMOOTHING: f32 = 0.2;

#[derive(Clone, Copy, Default)]
struct Flow {
    density: f32, momentum: [f32;3], energy: f32, pressure: f32, velocity: [f32;3],
    speed2: f32, speed: f32, sound: f32, momentum_flux: [[f32;3];3], energy_flux: [f32;3],
}
#[inline(never)] fn add32(a:f32,b:f32)->f32{a+b}
#[inline(never)] fn sub32(a:f32,b:f32)->f32{a-b}
#[inline(never)] fn mul32(a:f32,b:f32)->f32{a*b}
#[inline(never)] fn div32(a:f32,b:f32)->f32{a/b}

fn read_state(v:&[i64])->Option<Flow>{
    let mut raw=[0.0f32;5];
    for i in 0..5{if v[i]<0||v[i]>u32::MAX as i64{return None;}let bits=v[i] as u32;if bits&0x7f800000==0x7f800000{return None;}raw[i]=f32::from_bits(bits);}
    if raw[0]<0.5||raw[0]>2.0||raw[1].abs()>1.0||raw[2].abs()>1.0||raw[3].abs()>1.0||raw[4]<1.0||raw[4]>5.0{return None;}
    let mut f=Flow::default();f.density=raw[0];f.momentum=[raw[1],raw[2],raw[3]];f.energy=raw[4];
    for d in 0..3{f.velocity[d]=div32(f.momentum[d],f.density);}
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));
    let kinetic=mul32(mul32(0.5,f.density),f.speed2);f.pressure=mul32(sub32(GAMMA,1.0),sub32(f.energy,kinetic));
    if !f.pressure.is_finite()||f.pressure<=0.0{return None;}f.speed=f.speed2.sqrt();f.sound=(div32(mul32(GAMMA,f.pressure),f.density)).sqrt();
    let de_p=add32(f.energy,f.pressure);
    f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for d in 0..3{f.energy_flux[d]=mul32(f.velocity[d],de_p);}
    if !f.speed.is_finite()||!f.sound.is_finite(){return None;}Some(f)
}

fn farfield()->Flow{
    let mut f=Flow::default();f.density=1.4;f.pressure=1.0;f.sound=(div32(mul32(GAMMA,f.pressure),f.density)).sqrt();f.speed=mul32(1.2,f.sound);f.velocity=[f.speed,0.0,0.0];
    for d in 0..3{f.momentum[d]=mul32(f.density,f.velocity[d]);}
    f.energy=add32(mul32(f.density,mul32(0.5,mul32(f.speed,f.speed))),div32(f.pressure,sub32(GAMMA,1.0)));f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));let de_p=add32(f.energy,f.pressure);
    f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for d in 0..3{f.energy_flux[d]=mul32(f.velocity[d],de_p);}f
}
fn round_away(x:f32)->i64{let scaled=f64::from(x)*1000.0;if scaled<0.0{-((-scaled+0.5).floor() as i64)}else{(scaled+0.5).floor() as i64}}

#[no_mangle]
pub unsafe extern "C" fn rodinia_euler3d_flux(values:*const i64,length:usize)->i64{
    if values.is_null()||length!=INPUTS{return -1;}let v=unsafe{std::slice::from_raw_parts(values,length)};let Some(center)=read_state(&v[..5])else{return -1;};
    let mut kinds=[0i64;4];let mut normals=[[0.0f32;3];4];let mut neighbors=[Flow::default();4];
    for face in 0..4{let at=5+9*face;kinds[face]=v[at];if !(-2..=0).contains(&kinds[face]){return -1;}
        for d in 0..3{let raw=v[at+1+d];if raw<0||raw>u32::MAX as i64{return -1;}let bits=raw as u32;if bits&0x7f800000==0x7f800000{return -1;}normals[face][d]=f32::from_bits(bits);if normals[face][d].abs()>1.0{return -1;}}
        let Some(state)=read_state(&v[at+4..at+9])else{return -1;};neighbors[face]=state;
    }
    let far=farfield();let mut flux_density=0.0f32;let mut flux_energy=0.0f32;let mut flux_momentum=[0.0f32;3];
    for face in 0..4{let [nx,ny,nz]=normals[face];let normal_len=add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)).sqrt();
        if kinds[face]==0{let nb=neighbors[face];let mut factor=mul32(mul32(mul32(-normal_len,SMOOTHING),0.5),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound));
            flux_density=add32(flux_density,mul32(factor,sub32(center.density,nb.density)));flux_energy=add32(flux_energy,mul32(factor,sub32(center.energy,nb.energy)));
            for c in 0..3{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])));}
            let ns=[nx,ny,nz];for axis in 0..3{factor=mul32(0.5,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for c in 0..3{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(nb.momentum_flux[axis][c],center.momentum_flux[axis][c])));}}
        }else if kinds[face]==-1{flux_momentum[0]=add32(flux_momentum[0],mul32(nx,center.pressure));flux_momentum[1]=add32(flux_momentum[1],mul32(ny,center.pressure));flux_momentum[2]=add32(flux_momentum[2],mul32(nz,center.pressure));
        }else{let ns=[nx,ny,nz];for axis in 0..3{let factor=mul32(0.5,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for c in 0..3{flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(far.momentum_flux[axis][c],center.momentum_flux[axis][c])));}}}
    }
    let components=[flux_density,flux_momentum[0],flux_momentum[1],flux_momentum[2],flux_energy];let mut checksum=0i64;
    for i in 0..5{if !components[i].is_finite(){return -1;}checksum+=(i as i64+1)*round_away(components[i]);}checksum
}
