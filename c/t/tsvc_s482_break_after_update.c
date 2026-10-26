#include <math.h>
#include <stddef.h>
long long tsvc_s482_break_after_update(const double*x,size_t l,double*y,size_t cap){
 if(!x||l<5||l>194)return -1;double rn=x[0],rp=x[1];
 if(!isfinite(rn)||trunc(rn)!=rn||rn<1||rn>64||!isfinite(rp)||trunc(rp)!=rp||rp<1||rp>8)return -1;
 size_t n=(size_t)rn,passes=(size_t)rp;if(l!=2+3*n)return -1;
 for(size_t i=2;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double a[64];for(size_t i=0;i<n;i++)a[i]=x[2+i];size_t b=2+n,c=2+2*n;
 for(size_t pass=0;pass<passes;pass++)for(size_t i=0;i<n;i++){a[i]+=x[b+i]*x[c+i];if(x[c+i]>x[b+i])break;}
 for(size_t i=0;i<n;i++)y[i]=a[i];return (long long)n;
}
