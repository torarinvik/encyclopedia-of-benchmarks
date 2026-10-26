#include <math.h>
#include <stddef.h>
long long tsvc_s2710_nested_scalar_vector_branch_update(const double*x,size_t l,double*y,size_t cap){
 if(!x||l<58||l>323)return -1;double rn=x[0],rp=x[1],scalar=x[2];
 if(!isfinite(rn)||trunc(rn)!=rn||rn<11||rn>64||!isfinite(rp)||trunc(rp)!=rp||rp<1||rp>8||!isfinite(scalar)||trunc(scalar)!=scalar||fabs(scalar)>1)return -1;
 size_t n=(size_t)rn,passes=(size_t)rp;if(l!=3+5*n)return -1;
 for(size_t i=3;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;
 if(!y||cap<3*n)return -2;double a[64],b[64],c[64];for(size_t i=0;i<n;i++){a[i]=x[3+i];b[i]=x[3+n+i];c[i]=x[3+2*n+i];}
 for(size_t pass=0;pass<passes;pass++)for(size_t i=0;i<n;i++){double d=x[3+3*n+i],e=x[3+4*n+i];if(a[i]>b[i]){a[i]+=b[i]*d;c[i]+=d*d;}else{b[i]=a[i]+e*e;if(scalar>0)c[i]=a[i]+d*d;else c[i]+=e*e;}}
 for(size_t i=0;i<n;i++){y[i]=a[i];y[n+i]=b[i];y[2*n+i]=c[i];}return (long long)(3*n);
}
