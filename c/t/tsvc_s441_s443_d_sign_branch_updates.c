#include <math.h>
#include <stddef.h>
long long tsvc_s441_s443_d_sign_branch_updates(const double*x,size_t l,double*y,size_t cap){
 if(!x||l<7||l>259)return -1;double rm=x[0],rn=x[1],rp=x[2];
 if(!isfinite(rm)||trunc(rm)!=rm||(rm!=0&&rm!=1)||!isfinite(rn)||trunc(rn)!=rn||rn<1||rn>64||!isfinite(rp)||trunc(rp)!=rp||rp<1||rp>8)return -1;
 size_t mode=(size_t)rm,n=(size_t)rn,passes=(size_t)rp;if(l!=3+4*n)return -1;
 for(size_t i=3;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double a[64];size_t b=3+n,c=3+2*n,d=3+3*n;for(size_t i=0;i<n;i++)a[i]=x[3+i];
 for(size_t pass=0;pass<passes;pass++)for(size_t i=0;i<n;i++){if(mode==0){if(x[d+i]<0)a[i]+=x[b+i]*x[c+i];else if(x[d+i]==0)a[i]+=x[b+i]*x[b+i];else a[i]+=x[c+i]*x[c+i];}else if(x[d+i]<=0)a[i]+=x[b+i]*x[c+i];else a[i]+=x[b+i]*x[b+i];}
 for(size_t i=0;i<n;i++)y[i]=a[i];return (long long)n;
}
