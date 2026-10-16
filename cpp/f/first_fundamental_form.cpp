#include <cstddef>
#include <cstdint>
static std::uint64_t feed(std::uint64_t h,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(int b=0;b<8;b++){h^=static_cast<std::uint8_t>(u>>(8*b));h*=UINT64_C(0x100000001b3);}return h;}
static void product(const std::int64_t*a,const std::int64_t*b,std::int64_t*o){o[0]+=a[0]*b[0];o[1]+=a[0]*b[1]+a[1]*b[0];o[2]+=a[0]*b[2]+a[2]*b[0];o[3]+=a[1]*b[1];o[4]+=a[1]*b[2]+a[2]*b[1];o[5]+=a[2]*b[2];}
extern "C" std::int64_t first_fundamental_form(const std::int64_t*v,std::size_t n){if(!v||n!=18)return -1;for(std::size_t i=0;i<n;i++)if(v[i]<-100||v[i]>100)return -1;std::int64_t ru[9],rv[9],o[18]={};for(int k=0;k<3;k++){auto i=6*k;ru[3*k]=v[i+1];ru[3*k+1]=2*v[i+3];ru[3*k+2]=v[i+4];rv[3*k]=v[i+2];rv[3*k+1]=v[i+4];rv[3*k+2]=2*v[i+5];}for(int k=0;k<3;k++){product(ru+3*k,ru+3*k,o);product(ru+3*k,rv+3*k,o+6);product(rv+3*k,rv+3*k,o+12);}std::uint64_t h=UINT64_C(0xcbf29ce484222325);for(auto x:o)h=feed(h,x);return static_cast<std::int64_t>(h);}
