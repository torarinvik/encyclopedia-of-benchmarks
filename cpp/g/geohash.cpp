#include <cstddef>
#include <cstdint>
namespace { constexpr char alphabet[]="0123456789bcdefghjkmnpqrstuvwxyz"; }
extern "C" std::int64_t geohash(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n!=2||v[0]<-90000000||v[0]>90000000||v[1]<-180000000||v[1]>180000000)return -1;
 double lat=static_cast<double>(v[0])/1000000.0,lon=static_cast<double>(v[1])/1000000.0,latlo=-90,lathi=90,lonlo=-180,lonhi=180;std::uint8_t b[12];int bit=0,val=0;bool islon=true;std::size_t p=0;
 while(p<12){double mid;if(islon){mid=(lonlo+lonhi)/2;if(lon>mid){val|=1<<(4-bit);lonlo=mid;}else lonhi=mid;}else{mid=(latlo+lathi)/2;if(lat>mid){val|=1<<(4-bit);latlo=mid;}else lathi=mid;}islon=!islon;if(bit<4)bit++;else{b[p++]=alphabet[val];bit=val=0;}}
 if(!out||cap<12)return -2;for(std::size_t i=0;i<12;i++)out[i]=b[i];return 12;
}
