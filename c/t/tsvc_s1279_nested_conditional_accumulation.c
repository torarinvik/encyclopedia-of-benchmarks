#include <math.h>
#include <stddef.h>
long long tsvc_s1279_nested_conditional_accumulation(const double*x,size_t l,double*y,size_t cap){
 if(!x||l<7||l>322)return -1;double rn=x[0],rp=x[1];
 if(!isfinite(rn)||trunc(rn)!=rn||rn<1||rn>64||!isfinite(rp)||trunc(rp)!=rp||rp<1||rp>8)return -1;
 size_t n=(size_t)rn,passes=(size_t)rp;if(l!=2+5*n)return -1;
 for(size_t i=2;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(!y||cap<n)return -2;double c[64];for(size_t i=0;i<n;i++)c[i]=x[2+2*n+i];
 for(size_t pass=0;pass<passes;pass++)for(size_t i=0;i<n;i++){double a=x[2+i],b=x[2+n+i];if(a<0){if(b>a)c[i]+=x[2+3*n+i]*x[2+4*n+i];}}
 for(size_t i=0;i<n;i++)y[i]=c[i];return (long long)n;
}
