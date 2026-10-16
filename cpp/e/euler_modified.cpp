#include <cstddef>
#include <cstdint>
#include <cstring>
static void put64(std::uint8_t*o,std::size_t i,double x){std::uint64_t b;std::memcpy(&b,&x,8);for(std::size_t k=0;k<8;k++)o[i*8+k]=static_cast<std::uint8_t>(b>>(8*k));}
extern "C" std::int64_t euler_modified(const std::int64_t*v,std::size_t n,std::uint8_t*out,std::size_t cap)noexcept{
 if(!v||n!=2||v[0]<1||v[0]>8||v[1]<1||v[1]>4)return -1;auto steps=static_cast<std::size_t>(v[0]);if(!out||cap<(steps+1)*8)return -2;
 constexpr double h=0.25;double x=0.0,y=static_cast<double>(v[1]);put64(out,0,y);
 for(std::size_t i=0;i<steps;i++){double f0=-2.0*x*y*y;double predictor=y+h*f0;double f1=-2.0*(x+h)*predictor*predictor;y=y+(h/2.0)*(f0+f1);x+=h;put64(out,i+1,y);}return static_cast<std::int64_t>((steps+1)*8);
}
