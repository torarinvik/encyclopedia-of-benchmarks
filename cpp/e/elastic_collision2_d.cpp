#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t elastic_collision2_d(const std::int64_t *v, std::size_t n) noexcept {
    if (!v || n != 12) return -1;
    for (std::size_t i=0;i<12;++i) {
        if ((i==0||i==1||i==6||i==7) && (v[i] < -200000 || v[i] > 200000)) return -1;
        if ((i==2||i==3||i==8||i==9) && (v[i] < -5000 || v[i] > 5000)) return -1;
    }
    if(v[4]<1000||v[4]>100000||v[10]<1000||v[10]>100000||v[5]<1||v[5]>10000||v[11]<1||v[11]>10000)return -1;
    const double dx=double(v[6])-double(v[0]),dy=double(v[7])-double(v[1]),dist=std::hypot(dx,dy);if(dist==0)return -1;
    double ox=double(v[2]),oy=double(v[3]);
    if(!(dist<double(v[5])+double(v[11]))){const double nx=dx/dist,ny=dy/dist;const double rv=(double(v[8])-v[2])*nx+(double(v[9])-v[3])*ny;if(rv<=0){const double j=-2*rv/(1.0/double(v[4])+1.0/double(v[10]));ox-=j*nx/double(v[4]);oy-=j*ny/double(v[4]);}}
    const auto qx=std::int64_t(std::floor(ox+0.5)),qy=std::int64_t(std::floor(oy+0.5));if(qx < -32768||qx>32767||qy < -32768||qy>32767)return -1;
    return ((qx&0xffff)<<16)|(qy&0xffff);
}
