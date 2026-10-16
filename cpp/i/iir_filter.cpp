#include <cstddef>
#include <cstdint>
#include <cstring>
static void put64(std::uint8_t*o,std::size_t i,double x){std::uint64_t b;std::memcpy(&b,&x,8);for(std::size_t k=0;k<8;k++)o[i*8+k]=static_cast<std::uint8_t>(b>>(8*k));}
extern "C" std::int64_t iir_filter(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap)noexcept{
 if(!v||n<7||n>26||v[0]<1||v[0]>3||v[1]<1||v[1]>16)return -1;auto order=static_cast<std::size_t>(v[0]),samples=static_cast<std::size_t>(v[1]);if(n!=4+2*order+samples)return -1;double a[4],b[4],xh[3]={},yh[3]={};
 for(std::size_t i=0;i<=order;i++){auto av=v[2+i],bv=v[3+order+i];if(av < -500||av>2000||bv < -500||bv>500)return -1;a[i]=double(av)/1000.0;b[i]=double(bv)/1000.0;}if(a[0]<0.5)return -1;for(std::size_t i=0;i<samples;i++)if(v[4+2*order+i]<-1000||v[4+2*order+i]>1000)return -1;
 auto bytes=samples*8;if(!out||cap<bytes)return -2;for(std::size_t s=0;s<samples;s++){double x=double(v[4+2*order+s])/1000.0;double result=0.0;for(std::size_t i=1;i<=order;i++)result+=b[i]*xh[i-1]-a[i]*yh[i-1];result=(result+b[0]*x)/a[0];for(std::size_t i=order-1;i>0;i--){xh[i]=xh[i-1];yh[i]=yh[i-1];}xh[0]=x;yh[0]=result;put64(out,s,result);}return static_cast<std::int64_t>(bytes);
}
