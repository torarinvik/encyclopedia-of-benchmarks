#include <cmath>
#include <cstddef>
extern "C" long long tsvc_s441_s443_d_sign_branch_updates(const double*x,std::size_t l,double*y,std::size_t cap){
 if(!x||l<7||l>259)return -1;double rm=x[0],rn=x[1],rp=x[2];if(!std::isfinite(rm)||std::trunc(rm)!=rm||(rm!=0&&rm!=1)||!std::isfinite(rn)||std::trunc(rn)!=rn||rn<1||rn>64||!std::isfinite(rp)||std::trunc(rp)!=rp||rp<1||rp>8)return -1;
 auto mode=(std::size_t)rm;auto n=(std::size_t)rn;auto passes=(std::size_t)rp;if(l!=3+4*n)return -1;for(std::size_t i=3;i<l;i++)if(!std::isfinite(x[i])||std::trunc(x[i])!=x[i]||std::abs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double a[64];auto b=3+n;auto c=3+2*n;auto d=3+3*n;for(std::size_t i=0;i<n;i++)a[i]=x[3+i];
 for(std::size_t pass=0;pass<passes;pass++)for(std::size_t i=0;i<n;i++){if(mode==0){if(x[d+i]<0)a[i]+=x[b+i]*x[c+i];else if(x[d+i]==0)a[i]+=x[b+i]*x[b+i];else a[i]+=x[c+i]*x[c+i];}else if(x[d+i]<=0)a[i]+=x[b+i]*x[c+i];else a[i]+=x[b+i]*x[b+i];}
 for(std::size_t i=0;i<n;i++)y[i]=a[i];return static_cast<long long>(n);
}
