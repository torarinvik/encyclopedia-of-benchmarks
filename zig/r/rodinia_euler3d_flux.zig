// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
const std = @import("std");
const INPUTS: usize = 41;
const GAMMA: f32 = 1.4;
const SMOOTHING: f32 = 0.2;

const Flow = struct {
    density: f32 = 0,
    momentum: [3]f32 = .{0,0,0},
    energy: f32 = 0,
    pressure: f32 = 0,
    velocity: [3]f32 = .{0,0,0},
    speed2: f32 = 0,
    speed: f32 = 0,
    sound: f32 = 0,
    momentum_flux: [3][3]f32 = .{.{0,0,0},.{0,0,0},.{0,0,0}},
    energy_flux: [3]f32 = .{0,0,0},
};
fn add32(a:f32,b:f32) f32 { @setFloatMode(.strict); return a+b; }
fn sub32(a:f32,b:f32) f32 { @setFloatMode(.strict); return a-b; }
fn mul32(a:f32,b:f32) f32 { @setFloatMode(.strict); return a*b; }
fn div32(a:f32,b:f32) f32 { @setFloatMode(.strict); return a/b; }
fn sqrt32(x:f32) f32 { @setFloatMode(.strict); return @sqrt(x); }

fn readState(v:[*]const i64) ?Flow {
    var raw:[5]f32=.{0,0,0,0,0};
    for(0..5)|i|{
        if(v[i]<0 or v[i]>std.math.maxInt(u32))return null;
        const bits:u32=@intCast(v[i]);if(bits&0x7f800000==0x7f800000)return null;
        raw[i]=@bitCast(bits);
    }
    if(raw[0]<0.5 or raw[0]>2.0 or @abs(raw[1])>1.0 or @abs(raw[2])>1.0 or @abs(raw[3])>1.0 or raw[4]<1.0 or raw[4]>5.0)return null;
    var f=Flow{.density=raw[0],.momentum=.{raw[1],raw[2],raw[3]},.energy=raw[4]};
    for(0..3)|d|f.velocity[d]=div32(f.momentum[d],f.density);
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));
    const kinetic=mul32(mul32(0.5,f.density),f.speed2);f.pressure=mul32(sub32(GAMMA,1.0),sub32(f.energy,kinetic));
    if(!std.math.isFinite(f.pressure) or f.pressure<=0)return null;
    f.speed=sqrt32(f.speed2);f.sound=sqrt32(div32(mul32(GAMMA,f.pressure),f.density));const de_p=add32(f.energy,f.pressure);
    f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(0..3)|d|f.energy_flux[d]=mul32(f.velocity[d],de_p);
    if(!std.math.isFinite(f.speed) or !std.math.isFinite(f.sound))return null;return f;
}

fn farfield() Flow {
    var f=Flow{.density=1.4,.pressure=1.0};f.sound=sqrt32(div32(mul32(GAMMA,f.pressure),f.density));f.speed=mul32(1.2,f.sound);f.velocity=.{f.speed,0,0};
    for(0..3)|d|f.momentum[d]=mul32(f.density,f.velocity[d]);
    f.energy=add32(mul32(f.density,mul32(0.5,mul32(f.speed,f.speed))),div32(f.pressure,sub32(GAMMA,1.0)));
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));const de_p=add32(f.energy,f.pressure);
    f.momentum_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.momentum_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.momentum_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.momentum_flux[1][0]=f.momentum_flux[0][1];f.momentum_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.momentum_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.momentum_flux[2][0]=f.momentum_flux[0][2];f.momentum_flux[2][1]=f.momentum_flux[1][2];f.momentum_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(0..3)|d|f.energy_flux[d]=mul32(f.velocity[d],de_p);return f;
}
fn roundAway(x:f32)i64{const scaled=@as(f64,x)*1000.0;if(scaled<0)return -@as(i64,@intFromFloat(@floor(-scaled+0.5)));return @intFromFloat(@floor(scaled+0.5));}

pub export fn rodinia_euler3d_flux(values:?[*]const i64,length:usize)i64{
    const v=values orelse return -1;if(length!=INPUTS)return -1;const center=readState(v) orelse return -1;
    var kinds=[_]i64{0}**4;var normals=[_][3]f32{.{0,0,0}}**4;var neighbors=[_]Flow{Flow{}}**4;
    for(0..4)|face|{const at=5+face*9;kinds[face]=v[at];if(kinds[face] < -2 or kinds[face]>0)return -1;
        for(0..3)|d|{const raw=v[at+1+d];if(raw<0 or raw>std.math.maxInt(u32))return -1;const bits:u32=@intCast(raw);if(bits&0x7f800000==0x7f800000)return -1;normals[face][d]=@bitCast(bits);if(@abs(normals[face][d])>1.0)return -1;}
        neighbors[face]=readState(v+at+4) orelse return -1;
    }
    const far=farfield();var fd:f32=0;var fe:f32=0;var fm=[_]f32{0}**3;
    for(0..4)|face|{const nx=normals[face][0];const ny=normals[face][1];const nz=normals[face][2];const normal_len=sqrt32(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)));
        if(kinds[face]==0){const nb=neighbors[face];var factor=mul32(mul32(mul32(-normal_len,SMOOTHING),0.5),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound));
            fd=add32(fd,mul32(factor,sub32(center.density,nb.density)));fe=add32(fe,mul32(factor,sub32(center.energy,nb.energy)));for(0..3)|c|fm[c]=add32(fm[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])));
            const ns=[_]f32{nx,ny,nz};for(0..3)|axis|{factor=mul32(0.5,ns[axis]);fd=add32(fd,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));fe=add32(fe,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for(0..3)|c|fm[c]=add32(fm[c],mul32(factor,add32(nb.momentum_flux[axis][c],center.momentum_flux[axis][c])));}
        }else if(kinds[face]==-1){fm[0]=add32(fm[0],mul32(nx,center.pressure));fm[1]=add32(fm[1],mul32(ny,center.pressure));fm[2]=add32(fm[2],mul32(nz,center.pressure));
        }else{const ns=[_]f32{nx,ny,nz};for(0..3)|axis|{const factor=mul32(0.5,ns[axis]);fd=add32(fd,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));fe=add32(fe,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for(0..3)|c|fm[c]=add32(fm[c],mul32(factor,add32(far.momentum_flux[axis][c],center.momentum_flux[axis][c])));}}
    }
    const comp=[_]f32{fd,fm[0],fm[1],fm[2],fe};var checksum:i64=0;for(0..5)|i|{if(!std.math.isFinite(comp[i]))return -1;checksum+=@as(i64,@intCast(i+1))*roundAway(comp[i]);}return checksum;
}
