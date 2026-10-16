#include <math.h>
#include <stddef.h>
#include <stdint.h>
int64_t dimensionality_reduction_pca(const double *in,size_t n,double *out,size_t cap){
 if(!in||n<7||in[0]!=2||in[2]!=1||in[1]!=(double)(size_t)in[1]||in[1]<2||in[1]>8||n!=3+2*(size_t)in[1])return -1;
 size_t m=(size_t)in[1]; double x[8],y[8],mx=0,my=0;
 for(size_t i=0;i<m;i++){x[i]=in[3+i];y[i]=in[3+m+i];if(!isfinite(x[i])||!isfinite(y[i])||fabs(x[i])>1e6||fabs(y[i])>1e6)return -1;mx+=x[i];my+=y[i];}
 mx/=m;my/=m;double a=0,b=0,d=0;
 for(size_t i=0;i<m;i++){double dx=x[i]-mx,dy=y[i]-my;a+=dx*dx;b+=dx*dy;d+=dy*dy;}
 a/=m;b/=m;d/=m;if(!(b>0)||fabs(a-d)+fabs(b)==0)return -1;
 double t=0.5*atan2(2*b,a-d),vx=cos(t),vy=sin(t);
 if(!out||cap<m)return -2;for(size_t i=0;i<m;i++)out[i]=vx*x[i]+vy*y[i];return (int64_t)m;
}
