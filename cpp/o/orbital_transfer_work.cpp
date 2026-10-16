#include <cstddef>
#include <cstdint>
#include <cstring>
static void put_double(std::uint8_t*out,double x){std::uint64_t b;std::memcpy(&b,&x,8);for(int k=0;k<8;k++)out[k]=static_cast<std::uint8_t>(b>>(8*k));}
extern "C" std::int64_t orbital_transfer_work(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){if(!v||n!=4)return -1;if(v[0]<-1000000000||v[0]>1000000000||v[1]<-1000000||v[1]>1000000||v[2]<1||v[2]>1000000000||v[3]<1||v[3]>1000000000)return -1;if(!out||cap<8)return -2;double w=(6.67430e-11*static_cast<double>(v[0])*static_cast<double>(v[1])/2.0)*(1.0/static_cast<double>(v[2])-1.0/static_cast<double>(v[3]));put_double(out,w);return 8;}
