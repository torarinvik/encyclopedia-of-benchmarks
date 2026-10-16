#include <math.h>
#include <stddef.h>
#include <stdint.h>

int64_t dimensionality_reduction_lda(const double *v,size_t n,double *out,size_t cap){
 if(!v||n<16||v[0]!=2||v[2]!=2||v[3]!=1||v[1]!=(double)(size_t)v[1]||v[1]<4||v[1]>8||n!=4+3*(size_t)v[1])return -1;
 size_t m=(size_t)v[1], base=4+2*m;double x[8],y[8],labels[8],mu[2][2]={{0}},overall[2]={0};size_t counts[2]={0,0};
 for(size_t i=0;i<m;i++){x[i]=v[4+i];y[i]=v[4+m+i];labels[i]=v[base+i];if(!isfinite(x[i])||!isfinite(y[i])||fabs(x[i])>10000||fabs(y[i])>10000||(labels[i]!=0&&labels[i]!=1))return -1;size_t c=(size_t)labels[i];counts[c]++;mu[c][0]+=x[i];mu[c][1]+=y[i];overall[0]+=x[i];overall[1]+=y[i];}
 if(counts[0]<2||counts[1]<2)return -1;for(size_t c=0;c<2;c++){mu[c][0]/=counts[c];mu[c][1]/=counts[c];}overall[0]/=m;overall[1]/=m;
 double a=0,b=0,d=0;for(size_t i=0;i<m;i++){size_t c=(size_t)labels[i];double dx=x[i]-mu[c][0],dy=y[i]-mu[c][1];a+=dx*dx;b+=dx*dy;d+=dy*dy;}a/=m;b/=m;d/=m;double det=a*d-b*b;if(!(det>1e-12))return -1;
 double dx=mu[1][0]-mu[0][0],dy=mu[1][1]-mu[0][1],w0=(d*dx-b*dy)/det,w1=(a*dy-b*dx)/det,norm=sqrt(w0*w0+w1*w1);if(!(norm>1e-12))return -1;w0/=norm;w1/=norm;if(w0<0||(fabs(w0)<=1e-14&&w1<0)){w0=-w0;w1=-w1;}
 if(!out||cap<m)return -2;for(size_t i=0;i<m;i++)out[i]=w0*x[i]+w1*y[i];return (int64_t)m;
}
