#include <cstddef>
#include <cstdint>
namespace{void put(std::uint8_t*out,std::int64_t x){auto u=static_cast<std::uint64_t>(x);for(std::size_t b=0;b<8;++b)out[b]=std::uint8_t(u>>(8*b));}}
extern "C" std::int64_t ams_sketch(const std::int64_t*in,std::size_t len,std::uint8_t*out,std::size_t cap)noexcept{
 if(!in||len<4||len>116)return -1;auto d0=in[0],w0=in[1],k0=in[2],u0=in[3];if((d0!=1&&d0!=3&&d0!=5)||w0<1||w0>8||k0<1||k0>8||u0<0||u0>16)return -1;
 auto d=std::size_t(d0),w=std::size_t(w0),k=std::size_t(k0),u=std::size_t(u0),start=4+2*d*k;if(len!=start+2*u)return -1;
 for(std::size_t r=0;r<d;++r)for(std::size_t key=0;key<k;++key){auto p=4+2*(r*k+key);if(in[p]<0||in[p]>=w0||(in[p+1]!=-1&&in[p+1]!=1))return -1;}
 for(std::size_t i=0;i<u;++i){auto key=in[start+2*i],weight=in[start+2*i+1];if(key<0||key>=k0||weight< -1000||weight>1000)return -1;}
 std::int64_t c[5][8]{},e[5]{};for(std::size_t i=0;i<u;++i){auto key=std::size_t(in[start+2*i]);auto weight=in[start+2*i+1];for(std::size_t r=0;r<d;++r){auto p=4+2*(r*k+key);auto b=std::size_t(in[p]);c[r][b]+=weight*in[p+1];}}
 for(std::size_t r=0;r<d;++r)for(std::size_t b=0;b<w;++b)e[r]+=c[r][b]*c[r][b];
 for(std::size_t i=1;i<d;++i){auto x=e[i];auto j=i;while(j>0&&e[j-1]>x){e[j]=e[j-1];--j;}e[j]=x;}
 if(cap<8||!out)return -2;put(out,e[d/2]);return 8;
}
