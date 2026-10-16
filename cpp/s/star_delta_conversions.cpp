#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t star_delta_conversions(const std::int64_t *v,std::size_t n) noexcept {
 if(!v||n!=4||(v[0]!=0&&v[0]!=1))return -1;for(std::size_t i=1;i<4;++i)if(v[i]<1000||v[i]>100000)return -1;
 const double a=v[1],b=v[2],c=v[3];double out[3];if(v[0]==0){const double p=a*b+b*c+c*a;out[0]=p/a;out[1]=p/b;out[2]=p/c;}else{const double s=a+b+c;out[0]=b*c/s;out[1]=c*a/s;out[2]=a*b/s;}
 std::uint64_t h=0xcbf29ce484222325ULL;for(double x:out){const auto q=static_cast<std::int64_t>(std::floor(x+0.5));const auto u=static_cast<std::uint64_t>(q);for(unsigned j=0;j<8;++j){h^=static_cast<std::uint8_t>(u>>(8*j));h*=0x100000001b3ULL;}}return static_cast<std::int64_t>(h);
}
