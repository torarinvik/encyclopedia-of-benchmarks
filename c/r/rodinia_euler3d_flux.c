/* Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define E3D_INPUTS 41
#define E3D_GAMMA 1.4f
#define E3D_SMOOTHING 0.2f

typedef struct {
    float density, momentum[3], energy, pressure, velocity[3];
    float speed_squared, speed, sound;
    float momentum_flux[3][3], energy_flux[3];
} e3d_flow;

static float e3d_add(float a,float b){volatile float x=a+b;return x;}
static float e3d_sub(float a,float b){volatile float x=a-b;return x;}
static float e3d_mul(float a,float b){volatile float x=a*b;return x;}
static float e3d_div(float a,float b){volatile float x=a/b;return x;}
static float e3d_from_bits(uint32_t bits){float x;memcpy(&x,&bits,sizeof(x));return x;}

static int e3d_read_state(const int64_t *v, e3d_flow *f) {
    float raw[5];
    for (size_t i=0;i<5;i++) {
        if (v[i]<0 || (uint64_t)v[i]>UINT32_MAX) return 0;
        raw[i]=e3d_from_bits((uint32_t)v[i]);
        if (!isfinite(raw[i])) return 0;
    }
    if (raw[0]<0.5f || raw[0]>2.0f || fabsf(raw[1])>1.0f || fabsf(raw[2])>1.0f ||
        fabsf(raw[3])>1.0f || raw[4]<1.0f || raw[4]>5.0f) return 0;
    f->density=raw[0]; f->momentum[0]=raw[1]; f->momentum[1]=raw[2]; f->momentum[2]=raw[3]; f->energy=raw[4];
    for (int d=0;d<3;d++) f->velocity[d]=e3d_div(f->momentum[d],f->density);
    f->speed_squared=e3d_add(e3d_add(e3d_mul(f->velocity[0],f->velocity[0]),e3d_mul(f->velocity[1],f->velocity[1])),e3d_mul(f->velocity[2],f->velocity[2]));
    float kinetic=e3d_mul(e3d_mul(0.5f,f->density),f->speed_squared);
    f->pressure=e3d_mul(e3d_sub(E3D_GAMMA,1.0f),e3d_sub(f->energy,kinetic));
    if (!isfinite(f->pressure) || f->pressure<=0.0f) return 0;
    f->speed=sqrtf(f->speed_squared);
    f->sound=sqrtf(e3d_div(e3d_mul(E3D_GAMMA,f->pressure),f->density));
    float de_p=e3d_add(f->energy,f->pressure);
    f->momentum_flux[0][0]=e3d_add(e3d_mul(f->velocity[0],f->momentum[0]),f->pressure);
    f->momentum_flux[0][1]=e3d_mul(f->velocity[0],f->momentum[1]);
    f->momentum_flux[0][2]=e3d_mul(f->velocity[0],f->momentum[2]);
    f->momentum_flux[1][0]=f->momentum_flux[0][1];
    f->momentum_flux[1][1]=e3d_add(e3d_mul(f->velocity[1],f->momentum[1]),f->pressure);
    f->momentum_flux[1][2]=e3d_mul(f->velocity[1],f->momentum[2]);
    f->momentum_flux[2][0]=f->momentum_flux[0][2];
    f->momentum_flux[2][1]=f->momentum_flux[1][2];
    f->momentum_flux[2][2]=e3d_add(e3d_mul(f->velocity[2],f->momentum[2]),f->pressure);
    for (int d=0;d<3;d++) f->energy_flux[d]=e3d_mul(f->velocity[d],de_p);
    return isfinite(f->speed) && isfinite(f->sound);
}

static void e3d_farfield(e3d_flow *f) {
    f->density=1.4f; f->pressure=1.0f;
    f->sound=sqrtf(e3d_div(e3d_mul(E3D_GAMMA,f->pressure),f->density));
    f->speed=e3d_mul(1.2f,f->sound);
    f->velocity[0]=f->speed; f->velocity[1]=0.0f; f->velocity[2]=0.0f;
    for (int d=0;d<3;d++) f->momentum[d]=e3d_mul(f->density,f->velocity[d]);
    f->energy=e3d_add(e3d_mul(f->density,e3d_mul(0.5f,e3d_mul(f->speed,f->speed))),e3d_div(f->pressure,e3d_sub(E3D_GAMMA,1.0f)));
    f->speed_squared=e3d_add(e3d_add(e3d_mul(f->velocity[0],f->velocity[0]),e3d_mul(f->velocity[1],f->velocity[1])),e3d_mul(f->velocity[2],f->velocity[2]));
    float de_p=e3d_add(f->energy,f->pressure);
    f->momentum_flux[0][0]=e3d_add(e3d_mul(f->velocity[0],f->momentum[0]),f->pressure);
    f->momentum_flux[0][1]=e3d_mul(f->velocity[0],f->momentum[1]); f->momentum_flux[0][2]=e3d_mul(f->velocity[0],f->momentum[2]);
    f->momentum_flux[1][0]=f->momentum_flux[0][1]; f->momentum_flux[1][1]=e3d_add(e3d_mul(f->velocity[1],f->momentum[1]),f->pressure); f->momentum_flux[1][2]=e3d_mul(f->velocity[1],f->momentum[2]);
    f->momentum_flux[2][0]=f->momentum_flux[0][2]; f->momentum_flux[2][1]=f->momentum_flux[1][2]; f->momentum_flux[2][2]=e3d_add(e3d_mul(f->velocity[2],f->momentum[2]),f->pressure);
    for (int d=0;d<3;d++) f->energy_flux[d]=e3d_mul(f->velocity[d],de_p);
}

static int64_t e3d_round_away(float value) {
    double scaled=(double)value*1000.0;
    return scaled<0.0 ? -(int64_t)floor(-scaled+0.5) : (int64_t)floor(scaled+0.5);
}

int64_t rodinia_euler3d_flux(const int64_t *values,size_t length) {
    if(values==NULL||length!=E3D_INPUTS)return -1;
    e3d_flow center,far;
    if(!e3d_read_state(values,&center))return -1;
    int64_t kinds[4]; float normals[4][3]; e3d_flow neighbors[4];
    for(int face=0;face<4;face++){
        size_t at=5+(size_t)face*9; kinds[face]=values[at];
        if(kinds[face]<-2||kinds[face]>0)return -1;
        for(int d=0;d<3;d++){
            int64_t raw=values[at+1+(size_t)d]; if(raw<0||(uint64_t)raw>UINT32_MAX)return -1;
            normals[face][d]=e3d_from_bits((uint32_t)raw);
            if(!isfinite(normals[face][d])||fabsf(normals[face][d])>1.0f)return -1;
        }
        if(!e3d_read_state(values+at+4,&neighbors[face]))return -1;
    }
    e3d_farfield(&far);
    float flux_density=0.0f,flux_energy=0.0f,flux_momentum[3]={0.0f,0.0f,0.0f};
    for(int face=0;face<4;face++){
        float nx=normals[face][0],ny=normals[face][1],nz=normals[face][2];
        float normal_len=sqrtf(e3d_add(e3d_add(e3d_mul(nx,nx),e3d_mul(ny,ny)),e3d_mul(nz,nz)));
        if(kinds[face]==0){
            e3d_flow *nb=&neighbors[face];
            float factor=e3d_mul(e3d_mul(e3d_mul(-normal_len,E3D_SMOOTHING),0.5f),e3d_add(e3d_add(e3d_add(center.speed,nb->speed),center.sound),nb->sound));
            flux_density=e3d_add(flux_density,e3d_mul(factor,e3d_sub(center.density,nb->density)));
            flux_energy=e3d_add(flux_energy,e3d_mul(factor,e3d_sub(center.energy,nb->energy)));
            for(int c=0;c<3;c++)flux_momentum[c]=e3d_add(flux_momentum[c],e3d_mul(factor,e3d_sub(center.momentum[c],nb->momentum[c])));
            float normal[3]={nx,ny,nz};
            for(int axis=0;axis<3;axis++){
                factor=e3d_mul(0.5f,normal[axis]);
                flux_density=e3d_add(flux_density,e3d_mul(factor,e3d_add(nb->momentum[axis],center.momentum[axis])));
                flux_energy=e3d_add(flux_energy,e3d_mul(factor,e3d_add(nb->energy_flux[axis],center.energy_flux[axis])));
                for(int c=0;c<3;c++)flux_momentum[c]=e3d_add(flux_momentum[c],e3d_mul(factor,e3d_add(nb->momentum_flux[axis][c],center.momentum_flux[axis][c])));
            }
        }else if(kinds[face]==-1){
            flux_momentum[0]=e3d_add(flux_momentum[0],e3d_mul(nx,center.pressure));
            flux_momentum[1]=e3d_add(flux_momentum[1],e3d_mul(ny,center.pressure));
            flux_momentum[2]=e3d_add(flux_momentum[2],e3d_mul(nz,center.pressure));
        }else{
            float normal[3]={nx,ny,nz};
            for(int axis=0;axis<3;axis++){
                float factor=e3d_mul(0.5f,normal[axis]);
                flux_density=e3d_add(flux_density,e3d_mul(factor,e3d_add(far.momentum[axis],center.momentum[axis])));
                flux_energy=e3d_add(flux_energy,e3d_mul(factor,e3d_add(far.energy_flux[axis],center.energy_flux[axis])));
                for(int c=0;c<3;c++)flux_momentum[c]=e3d_add(flux_momentum[c],e3d_mul(factor,e3d_add(far.momentum_flux[axis][c],center.momentum_flux[axis][c])));
            }
        }
    }
    float result[5]={flux_density,flux_momentum[0],flux_momentum[1],flux_momentum[2],flux_energy};
    int64_t checksum=0;
    for(int i=0;i<5;i++){if(!isfinite(result[i]))return -1;checksum+=(int64_t)(i+1)*e3d_round_away(result[i]);}
    return checksum;
}
