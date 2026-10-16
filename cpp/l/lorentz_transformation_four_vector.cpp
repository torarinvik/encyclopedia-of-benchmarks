#include <cstddef>
#include <cstdint>
#include <cmath>
double lorentz_transformation_four_vector(const std::int64_t*v,std::size_t n){if(n!=6)return -1e300;auto vel=v[0],s=v[1],t=v[2],x=v[3],y=v[4],z=v[5];if(vel<1||vel>200000000||s<0||s>3||t< -1000000||t>1000000||x< -100000000||x>100000000||y< -100000000||y>100000000||z< -100000000||z>100000000)return -1e300;double b=double(vel)/299792458.0,g=1/std::sqrt(1-b*b),ct=(double(t)/1e6)*299792458.0,xx=double(x)/100,yy=double(y)/100,zz=double(z)/100;double out[4]={g*ct-g*b*xx,-g*b*ct+g*xx,yy,zz};return out[s];}
