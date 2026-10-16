#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" double pythagoras(const std::int64_t *v,std::size_t n) noexcept {
 if(!v||n!=6)return -1.0e300;for(std::size_t i=0;i<6;i++)if(v[i]<-1000000||v[i]>1000000)return -1.0e300;
 const double dx=static_cast<double>(v[3]-v[0]),dy=static_cast<double>(v[4]-v[1]),dz=static_cast<double>(v[5]-v[2]);return std::sqrt(dx*dx+dy*dy+dz*dz);
}
