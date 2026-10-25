// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
module rodinia_euler3d_flux;
import "math";
extern fn float sqrtf(float value);

const long INPUTS=41;
const float GAMMA=1.4f, SMOOTHING=0.2f;
struct Flow {
    float density; float[3] momentum; float energy; float pressure; float[3] velocity;
    float speed2; float speed; float sound; float[3][3] mom_flux; float[3] energy_flux;
}
fn float add32(float a,float b) @noinline{return a+b;}
fn float sub32(float a,float b) @noinline{return a-b;}
fn float mul32(float a,float b) @noinline{return a*b;}
fn float div32(float a,float b) @noinline{return a/b;}
fn float bits_f32(uint bits) @noinline{return @bitcast(float,bits);}

fn bool read_state(long* v,Flow* f){
    float[5] raw;
    for(usz i=0;i<5;i++){if(v[i]<0||v[i]>4294967295)return false;raw[i]=bits_f32((uint)v[i]);if(!math.is_finite((double)raw[i]))return false;}
    if(raw[0]<0.5f||raw[0]>2.0f||math.fabs((double)raw[1])>1.0||math.fabs((double)raw[2])>1.0||math.fabs((double)raw[3])>1.0||raw[4]<1.0f||raw[4]>5.0f)return false;
    f.density=raw[0];for(usz d=0;d<3;d++)f.momentum[d]=raw[d+1];f.energy=raw[4];
    for(usz d=0;d<3;d++)f.velocity[d]=div32(f.momentum[d],f.density);
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));
    float kinetic=mul32(mul32(0.5f,f.density),f.speed2);
    f.pressure=mul32(sub32(GAMMA,1.0f),sub32(f.energy,kinetic));if(!math.is_finite((double)f.pressure)||f.pressure<=0.0f)return false;
    f.speed=sqrtf(f.speed2);f.sound=sqrtf(div32(mul32(GAMMA,f.pressure),f.density));float de_p=add32(f.energy,f.pressure);
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(usz d=0;d<3;d++)f.energy_flux[d]=mul32(f.velocity[d],de_p);
    return math.is_finite((double)f.speed)&&math.is_finite((double)f.sound);
}
fn void farfield(Flow* f){
    f.density=1.4f;f.pressure=1.0f;f.sound=sqrtf(div32(mul32(GAMMA,f.pressure),f.density));f.speed=mul32(1.2f,f.sound);
    f.velocity[0]=f.speed;f.velocity[1]=0.0f;f.velocity[2]=0.0f;for(usz d=0;d<3;d++)f.momentum[d]=mul32(f.density,f.velocity[d]);
    f.energy=add32(mul32(f.density,mul32(0.5f,mul32(f.speed,f.speed))),div32(f.pressure,sub32(GAMMA,1.0f)));
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));float de_p=add32(f.energy,f.pressure);
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(usz d=0;d<3;d++)f.energy_flux[d]=mul32(f.velocity[d],de_p);
}
fn long round_away(float value){double scaled=(double)value*1000.0;return scaled<0.0?-(long)math.floor(-scaled+0.5):(long)math.floor(scaled+0.5);}

fn long rodinia_euler3d_flux(long* values,usz length) @export("rodinia_euler3d_flux") {
    if(values==null||length!=INPUTS)return -1;Flow center,far;if(!read_state(values,&center))return -1;
    long[4] kinds;float[4][3] normals;Flow[4] neighbors;
    for(usz face=0;face<4;face++){usz at=5+face*9;kinds[face]=values[at];if(kinds[face] < -2||kinds[face]>0)return -1;
        for(usz d=0;d<3;d++){long raw=values[at+1+d];if(raw<0||raw>4294967295)return -1;normals[face][d]=bits_f32((uint)raw);if(!math.is_finite((double)normals[face][d])||math.fabs((double)normals[face][d])>1.0)return -1;}
        if(!read_state(values+at+4,&neighbors[face]))return -1;
    }
    farfield(&far);float flux_density=0.0f,flux_energy=0.0f;float[3] flux_momentum={0.0f,0.0f,0.0f};
    for(usz face=0;face<4;face++){float nx=normals[face][0],ny=normals[face][1],nz=normals[face][2];float normal_len=sqrtf(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)));
        if(kinds[face]==0){Flow* nb=&neighbors[face];float factor=mul32(mul32(mul32(-normal_len,SMOOTHING),0.5f),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound));
            flux_density=add32(flux_density,mul32(factor,sub32(center.density,nb.density)));flux_energy=add32(flux_energy,mul32(factor,sub32(center.energy,nb.energy)));
            for(usz c=0;c<3;c++)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])));
            float[3] ns={nx,ny,nz};for(usz axis=0;axis<3;axis++){factor=mul32(0.5f,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for(usz c=0;c<3;c++)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(nb.mom_flux[axis][c],center.mom_flux[axis][c])));}
        }else if(kinds[face]==-1){flux_momentum[0]=add32(flux_momentum[0],mul32(nx,center.pressure));flux_momentum[1]=add32(flux_momentum[1],mul32(ny,center.pressure));flux_momentum[2]=add32(flux_momentum[2],mul32(nz,center.pressure));
        }else{float[3] ns={nx,ny,nz};for(usz axis=0;axis<3;axis++){float factor=mul32(0.5f,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for(usz c=0;c<3;c++)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(far.mom_flux[axis][c],center.mom_flux[axis][c])));}}
    }
    float[5] result={flux_density,flux_momentum[0],flux_momentum[1],flux_momentum[2],flux_energy};long checksum=0;
    for(usz i=0;i<5;i++){if(!math.is_finite((double)result[i]))return -1;checksum+=(long)(i+1)*round_away(result[i]);}return checksum;
}
