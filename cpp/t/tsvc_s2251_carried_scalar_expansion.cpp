#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s2251_carried_scalar_expansion(const double*x,std::size_t l,double*y,std::size_t c){if(!x||l<6||l>321)return -1;double r=x[0];if(!std::isfinite(r)||std::trunc(r)!=r||r<1||r>64)return -1;auto n=(std::size_t)r;if(l!=1+5*n)return -1;for(std::size_t i=1;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;if(!y||c<2*n)return -2;double a[64],b[64],s=0;for(std::size_t i=0;i<n;i++){a[i]=s*x[1+4*n+i];s=x[1+n+i]+x[1+2*n+i];b[i]=a[i]+x[1+3*n+i];}for(std::size_t i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];}return 2*n;}
