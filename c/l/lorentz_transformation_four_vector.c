#include <stddef.h>
#include <stdint.h>
#include <math.h>
#define C 299792458.0
double lorentz_transformation_four_vector(const int64_t*v,size_t n){if(n!=6)return -1e300;int64_t vel=v[0],s=v[1],t=v[2],x=v[3],y=v[4],z=v[5];if(vel<1||vel>200000000||s<0||s>3||t< -1000000||t>1000000||x< -100000000||x>100000000||y< -100000000||y>100000000||z< -100000000||z>100000000)return -1e300;double b=(double)vel/C,g=1/sqrt(1-b*b),ct=((double)t/1e6)*C,xx=(double)x/100,yy=(double)y/100,zz=(double)z/100;double out[4]={g*ct-g*b*xx,-g*b*ct+g*xx,yy,zz};return out[s];}
