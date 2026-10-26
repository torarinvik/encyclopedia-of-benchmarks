#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s1279_nested_conditional_accumulation(const double*x,std::size_t l,double*y,std::size_t cap){
 if(!x||l<7||l>322)return -1;double rn=x[0],rp=x[1];
 if(!std::isfinite(rn)||std::trunc(rn)!=rn||rn<1||rn>64||!std::isfinite(rp)||std::trunc(rp)!=rp||rp<1||rp>8)return -1;
 auto n=(std::size_t)rn;auto passes=(std::size_t)rp;if(l!=2+5*n)return -1;
 for(std::size_t i=2;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double c[64];for(std::size_t i=0;i<n;i++)c[i]=x[2+2*n+i];
 for(std::size_t pass=0;pass<passes;pass++)for(std::size_t i=0;i<n;i++){double a=x[2+i],b=x[2+n+i];if(a<0){if(b>a)c[i]+=x[2+3*n+i]*x[2+4*n+i];}}
 for(std::size_t i=0;i<n;i++)y[i]=c[i];return static_cast<long long>(n);
}
