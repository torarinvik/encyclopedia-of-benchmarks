#include <math.h>
#include <stddef.h>
long long tsvc_s242_fused_prefix_update(const double*x,size_t l,double*y,size_t cap){if(!x||l<7||l>259)return -1;double r=x[0];if(!isfinite(r)||trunc(r)!=r||r<1||r>64)return -1;size_t n=(size_t)r;if(l!=3+4*n)return -1;for(size_t i=1;i<l;i++)if(!isfinite(x[i])||trunc(x[i])!=x[i]||fabs(x[i])>1)return -1;if(!y||cap<n)return -2;double a[64];for(size_t i=0;i<n;i++)a[i]=x[3+i];double s1=x[1],s2=x[2];for(size_t i=1;i<n;i++){double v=a[i-1]+s1;v=v+s2;v=v+x[3+2*n+i];v=v+x[3+3*n+i];v=v+x[3+4*n+i];a[i]=v;}for(size_t i=0;i<n;i++)y[i]=a[i];return n;}
