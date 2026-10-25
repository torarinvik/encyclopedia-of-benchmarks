#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t cbench_rsynth_f0_flutter(const std::int64_t* input,std::size_t n){
 if(!input||n==0||n>4)return -1;if(n!=3||input[0]<0||input[0]>20000||input[1]<0||input[1]>100||input[2]<0||input[2]>1000000)return -1;
 const auto f0=input[0],flutter=input[1],t=input[2];const auto orig=f0/10;constexpr double pi=3.1415927;
 const double fla=double(flutter)/50.0,flb=double(orig)/100.0;
 const double a=std::sin(2.0*pi*12.7*double(t)),b=std::sin(2.0*pi*7.1*double(t)),c=std::sin(2.0*pi*4.7*double(t));
 const double delta=fla*flb*(a+b+c)*10.0;return f0+static_cast<std::int64_t>(delta);
}
