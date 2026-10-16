#include <algorithm>
#include <cmath>
#include <cstddef>
#include <cstdint>
static std::int64_t round_even(double x){const double f=std::floor(x),d=x-f;const auto q=static_cast<std::int64_t>(f);if(d<0.5)return q;if(d>0.5)return q+1;return(q&1)?q+1:q;}
extern "C" std::int64_t rgbhsvconversion(const std::int64_t*v,std::size_t n) noexcept{
 if(!v||n!=4)return -1;
 if(v[0]==0){if(v[1]<0||v[1]>360000||v[2]<0||v[2]>1000||v[3]<0||v[3]>1000)return -1;double h=v[1]/1000.0,s=v[2]/1000.0,val=v[3]/1000.0,c=val*s,sec=h/60,x=c*(1-std::abs(std::fmod(sec,2.0)-1)),m=val-c,r,g,b;if(sec<=1){r=c+m;g=x+m;b=m;}else if(sec<=2){r=x+m;g=c+m;b=m;}else if(sec<=3){r=m;g=c+m;b=x+m;}else if(sec<=4){r=m;g=x+m;b=c+m;}else if(sec<=5){r=x+m;g=m;b=c+m;}else{r=c+m;g=m;b=x+m;}return (round_even(255*r)<<16)|(round_even(255*g)<<8)|round_even(255*b);}
 if(v[0]!=1||v[1]<0||v[1]>255||v[2]<0||v[2]>255||v[3]<0||v[3]>255)return -1;double r=v[1]/255.0,g=v[2]/255.0,b=v[3]/255.0,mx=std::max(r,std::max(g,b)),mn=std::min(r,std::min(g,b)),c=mx-mn,s=mx==0?0:c/mx,h;if(c==0)h=0;else if(mx==r)h=60*((g-b)/c);else if(mx==g)h=60*(2+(b-r)/c);else h=60*(4+(r-g)/c);h=std::fmod(h+360,360);auto qh=round_even(h*1000),qs=round_even(s*1000000),qv=round_even(mx*1000000);return(qh<<40)|(qs<<20)|qv;
}
