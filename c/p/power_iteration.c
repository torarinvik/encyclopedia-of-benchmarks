#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define BAD -1e300
double power_iteration(const int64_t*v,size_t n){if(!v||n!=5)return BAD;for(size_t i=0;i<5;i++)if(v[i]<1||v[i]>1000)return BAD;double a=v[0],b=v[1],d=v[2];if(a*d<=b*b)return BAD;double x=v[3],y=v[4],previous=0.0;for(int it=0;it<100;it++){double w0=a*x+b*y,w1=b*x+d*y,norm=sqrt(w0*w0+w1*w1);if(norm==0)return BAD;x=w0/norm;y=w1/norm;double av0=a*x+b*y,av1=b*x+d*y,eig=x*av0+y*av1;double error=fabs(eig-previous)/eig;if(error<=1e-12||it==99)return eig;previous=eig;}return BAD;}
