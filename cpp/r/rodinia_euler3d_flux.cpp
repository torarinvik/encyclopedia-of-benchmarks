// Rodinia Euler3D bounded cell-flux profile; full notice: benchmarks/r/rodinia_euler3d_flux/LICENSE.txt.
#include <cmath>
#include <cstddef>
#include <cstdint>
#include <cstring>

namespace {
constexpr std::size_t inputs=41;
constexpr float gamma=1.4f, smoothing=0.2f;
struct Flow { float density,momentum[3],energy,pressure,velocity[3],speed2,speed,sound,mom_flux[3][3],energy_flux[3]; };
float add32(float a,float b){volatile float x=a+b;return x;}
float sub32(float a,float b){volatile float x=a-b;return x;}
float mul32(float a,float b){volatile float x=a*b;return x;}
float div32(float a,float b){volatile float x=a/b;return x;}
float from_bits(std::uint32_t bits){float x;std::memcpy(&x,&bits,sizeof(x));return x;}
bool read_state(const std::int64_t* v,Flow& f){
    float raw[5];for(std::size_t i=0;i<5;++i){if(v[i]<0||static_cast<std::uint64_t>(v[i])>UINT32_MAX)return false;raw[i]=from_bits(static_cast<std::uint32_t>(v[i]));if(!std::isfinite(raw[i]))return false;}
    if(raw[0]<0.5f||raw[0]>2.0f||std::fabs(raw[1])>1.0f||std::fabs(raw[2])>1.0f||std::fabs(raw[3])>1.0f||raw[4]<1.0f||raw[4]>5.0f)return false;
    f.density=raw[0];for(int d=0;d<3;++d)f.momentum[d]=raw[d+1];f.energy=raw[4];
    for(int d=0;d<3;++d)f.velocity[d]=div32(f.momentum[d],f.density);
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));
    const float kinetic=mul32(mul32(0.5f,f.density),f.speed2);
    f.pressure=mul32(sub32(gamma,1.0f),sub32(f.energy,kinetic));if(!std::isfinite(f.pressure)||f.pressure<=0.0f)return false;
    f.speed=std::sqrt(f.speed2);f.sound=std::sqrt(div32(mul32(gamma,f.pressure),f.density));
    const float de_p=add32(f.energy,f.pressure);
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(int d=0;d<3;++d)f.energy_flux[d]=mul32(f.velocity[d],de_p);
    return std::isfinite(f.speed)&&std::isfinite(f.sound);
}
void farfield(Flow& f){
    f.density=1.4f;f.pressure=1.0f;f.sound=std::sqrt(div32(mul32(gamma,f.pressure),f.density));f.speed=mul32(1.2f,f.sound);
    f.velocity[0]=f.speed;f.velocity[1]=0.0f;f.velocity[2]=0.0f;
    for(int d=0;d<3;++d)f.momentum[d]=mul32(f.density,f.velocity[d]);
    f.energy=add32(mul32(f.density,mul32(0.5f,mul32(f.speed,f.speed))),div32(f.pressure,sub32(gamma,1.0f)));
    f.speed2=add32(add32(mul32(f.velocity[0],f.velocity[0]),mul32(f.velocity[1],f.velocity[1])),mul32(f.velocity[2],f.velocity[2]));
    const float de_p=add32(f.energy,f.pressure);
    f.mom_flux[0][0]=add32(mul32(f.velocity[0],f.momentum[0]),f.pressure);f.mom_flux[0][1]=mul32(f.velocity[0],f.momentum[1]);f.mom_flux[0][2]=mul32(f.velocity[0],f.momentum[2]);
    f.mom_flux[1][0]=f.mom_flux[0][1];f.mom_flux[1][1]=add32(mul32(f.velocity[1],f.momentum[1]),f.pressure);f.mom_flux[1][2]=mul32(f.velocity[1],f.momentum[2]);
    f.mom_flux[2][0]=f.mom_flux[0][2];f.mom_flux[2][1]=f.mom_flux[1][2];f.mom_flux[2][2]=add32(mul32(f.velocity[2],f.momentum[2]),f.pressure);
    for(int d=0;d<3;++d)f.energy_flux[d]=mul32(f.velocity[d],de_p);
}
std::int64_t round_away(float value){const double x=static_cast<double>(value)*1000.0;return x<0.0?-static_cast<std::int64_t>(std::floor(-x+0.5)):static_cast<std::int64_t>(std::floor(x+0.5));}
}

extern "C" std::int64_t rodinia_euler3d_flux(const std::int64_t* values,std::size_t length){
    if(values==nullptr||length!=inputs)return -1;Flow center,far; if(!read_state(values,center))return -1;
    std::int64_t kind[4];float normal[4][3];Flow neighbor[4];
    for(int face=0;face<4;++face){const std::size_t at=5+static_cast<std::size_t>(face)*9;kind[face]=values[at];if(kind[face]<-2||kind[face]>0)return -1;
        for(int d=0;d<3;++d){const auto raw=values[at+1+static_cast<std::size_t>(d)];if(raw<0||static_cast<std::uint64_t>(raw)>UINT32_MAX)return -1;normal[face][d]=from_bits(static_cast<std::uint32_t>(raw));if(!std::isfinite(normal[face][d])||std::fabs(normal[face][d])>1.0f)return -1;}
        if(!read_state(values+at+4,neighbor[face]))return -1;
    }
    farfield(far);float flux_density=0.0f,flux_energy=0.0f,flux_momentum[3]={0.0f,0.0f,0.0f};
    for(int face=0;face<4;++face){const float nx=normal[face][0],ny=normal[face][1],nz=normal[face][2];const float normal_len=std::sqrt(add32(add32(mul32(nx,nx),mul32(ny,ny)),mul32(nz,nz)));
        if(kind[face]==0){Flow& nb=neighbor[face];float factor=mul32(mul32(mul32(-normal_len,smoothing),0.5f),add32(add32(add32(center.speed,nb.speed),center.sound),nb.sound));
            flux_density=add32(flux_density,mul32(factor,sub32(center.density,nb.density)));flux_energy=add32(flux_energy,mul32(factor,sub32(center.energy,nb.energy)));
            for(int c=0;c<3;++c)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,sub32(center.momentum[c],nb.momentum[c])));
            const float ns[3]={nx,ny,nz};for(int axis=0;axis<3;++axis){factor=mul32(0.5f,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(nb.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(nb.energy_flux[axis],center.energy_flux[axis])));for(int c=0;c<3;++c)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(nb.mom_flux[axis][c],center.mom_flux[axis][c])));}
        }else if(kind[face]==-1){flux_momentum[0]=add32(flux_momentum[0],mul32(nx,center.pressure));flux_momentum[1]=add32(flux_momentum[1],mul32(ny,center.pressure));flux_momentum[2]=add32(flux_momentum[2],mul32(nz,center.pressure));
        }else{const float ns[3]={nx,ny,nz};for(int axis=0;axis<3;++axis){const float factor=mul32(0.5f,ns[axis]);flux_density=add32(flux_density,mul32(factor,add32(far.momentum[axis],center.momentum[axis])));flux_energy=add32(flux_energy,mul32(factor,add32(far.energy_flux[axis],center.energy_flux[axis])));for(int c=0;c<3;++c)flux_momentum[c]=add32(flux_momentum[c],mul32(factor,add32(far.mom_flux[axis][c],center.mom_flux[axis][c])));}}
    }
    const float result[5]={flux_density,flux_momentum[0],flux_momentum[1],flux_momentum[2],flux_energy};std::int64_t checksum=0;
    for(int i=0;i<5;++i){if(!std::isfinite(result[i]))return -1;checksum+=static_cast<std::int64_t>(i+1)*round_away(result[i]);}return checksum;
}
