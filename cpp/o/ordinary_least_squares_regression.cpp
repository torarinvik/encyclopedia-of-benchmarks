#include <cstddef>
#include <cstdint>
#include <cstring>
static void put_double(std::uint8_t*out,std::size_t off,double x){std::uint64_t b;std::memcpy(&b,&x,8);for(std::size_t i=0;i<8;i++)out[off+i]=static_cast<std::uint8_t>(b>>(8*i));}
extern "C" std::int64_t ordinary_least_squares_regression(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap){
 if(!v||n<5||v[0]<2||v[0]>32||n!=1+2*static_cast<std::size_t>(v[0]))return -1;auto count=static_cast<std::size_t>(v[0]);double x[32],y[32],xm=0,ym=0;
 for(std::size_t i=0;i<count;i++){auto a=v[1+2*i],b=v[2+2*i];if(a < -10000||a>10000||b < -10000||b>10000)return -1;x[i]=static_cast<double>(a);y[i]=static_cast<double>(b);xm+=x[i];ym+=y[i];}xm/=count;ym/=count;double num=0,den=0;for(std::size_t i=0;i<count;i++){double dx=x[i]-xm;num+=dx*(y[i]-ym);den+=dx*dx;}if(den==0)return -1;double slope=num/den,intercept=ym-slope*xm;if(!out||cap<16)return -2;put_double(out,0,intercept);put_double(out,8,slope);return 16;
}
