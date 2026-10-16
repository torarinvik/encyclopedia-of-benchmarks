#include <cstddef>
#include <cstdint>
namespace { constexpr std::uint64_t OFFSET=UINT64_C(14695981039346656037),PRIME=UINT64_C(1099511628211); std::uint64_t feed(std::uint64_t h,std::int64_t v){auto b=static_cast<std::uint64_t>(v);for(unsigned s=0;s<64;s+=8)h=(h^static_cast<std::uint8_t>(b>>s))*PRIME;return h;} }
extern "C" std::int64_t pareto_optimization(const std::int64_t*a,std::size_t len){
 if(!a||len<2||len>514)return -1;auto r64=a[0],c64=a[1];if(r64<1||r64>64||c64<1||c64>8||len!=2+static_cast<std::size_t>(r64*c64))return -1;
 auto r=static_cast<std::size_t>(r64),c=static_cast<std::size_t>(c64);for(std::size_t k=0;k<r*c;k++)if(a[2+k]<-1000||a[2+k]>1000)return -1;
 bool keep[64]{};std::int64_t kept=0;for(std::size_t i=0;i<r;i++){keep[i]=true;for(std::size_t j=0;j<r;j++){if(i==j)continue;bool ge=true,gt=false;for(std::size_t x=0;x<c;x++){auto l=a[2+j*c+x],v=a[2+i*c+x];if(l<v)ge=false;if(l>v)gt=true;}if(ge&&(gt||j<i)){keep[i]=false;break;}}if(keep[i])kept++;}
 auto h=feed(OFFSET,kept);h=feed(h,c64);for(std::size_t i=0;i<r;i++)if(keep[i])for(std::size_t x=0;x<c;x++)h=feed(h,a[2+i*c+x]);return static_cast<std::int64_t>(h&UINT64_C(0x7fffffffffffffff));
}
