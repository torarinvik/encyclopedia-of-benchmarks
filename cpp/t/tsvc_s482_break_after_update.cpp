#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s482_break_after_update(const double*x,std::size_t l,double*y,std::size_t cap){
 if(!x||l<5||l>194)return -1;double rn=x[0],rp=x[1];if(!std::isfinite(rn)||std::trunc(rn)!=rn||rn<1||rn>64||!std::isfinite(rp)||std::trunc(rp)!=rp||rp<1||rp>8)return -1;
 auto n=(std::size_t)rn;auto passes=(std::size_t)rp;if(l!=2+3*n)return -1;for(std::size_t i=2;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double a[64];auto b=2+n;auto c=2+2*n;for(std::size_t i=0;i<n;i++)a[i]=x[2+i];
 for(std::size_t pass=0;pass<passes;pass++)for(std::size_t i=0;i<n;i++){a[i]+=x[b+i]*x[c+i];if(x[c+i]>x[b+i])break;}
 for(std::size_t i=0;i<n;i++)y[i]=a[i];return static_cast<long long>(n);
}
