#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" std::int64_t dimensionality_reduction_pca(const double* in,std::size_t n,double* out,std::size_t cap){
 if(!in||n<7||in[0]!=2||in[2]!=1||in[1]!=static_cast<double>(static_cast<std::size_t>(in[1]))||in[1]<2||in[1]>8||n!=3+2*static_cast<std::size_t>(in[1]))return -1;
 auto m=static_cast<std::size_t>(in[1]);double x[8],y[8],mx=0,my=0;for(std::size_t i=0;i<m;i++){x[i]=in[3+i];y[i]=in[3+m+i];if(!std::isfinite(x[i])||!std::isfinite(y[i])||std::abs(x[i])>1e6||std::abs(y[i])>1e6)return -1;mx+=x[i];my+=y[i];}mx/=m;my/=m;double a=0,b=0,d=0;for(std::size_t i=0;i<m;i++){double dx=x[i]-mx,dy=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy;}a/=m;b/=m;d/=m;if(!(b>0)||std::abs(a-d)+std::abs(b)==0)return -1;double t=.5*std::atan2(2*b,a-d),vx=std::cos(t),vy=std::sin(t);if(!out||cap<m)return -2;for(std::size_t i=0;i<m;i++)out[i]=vx*x[i]+vy*y[i];return static_cast<std::int64_t>(m);
}
