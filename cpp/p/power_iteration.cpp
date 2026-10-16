#include <cmath>
#include <cstddef>
#include <cstdint>
extern "C" double power_iteration(const std::int64_t*v,std::size_t n) noexcept {if(!v||n!=5)return -1e300;for(std::size_t i=0;i<5;++i)if(v[i]<1||v[i]>1000)return -1e300;const double a=v[0],b=v[1],d=v[2];if(a*d<=b*b)return -1e300;double x=v[3],y=v[4],previous=0;for(int it=0;it<100;++it){const double w0=a*x+b*y,w1=b*x+d*y,norm=std::sqrt(w0*w0+w1*w1);if(norm==0)return -1e300;x=w0/norm;y=w1/norm;const double av0=a*x+b*y,av1=b*x+d*y,eig=x*av0+y*av1;const double error=std::abs(eig-previous)/eig;if(error<=1e-12||it==99)return eig;previous=eig;}return -1e300;}
