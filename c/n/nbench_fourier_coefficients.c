#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define MAX_N 16
#define INVALID_RESULT (-1e300)
static double term(double x,double omega,int select){double base=pow(x+1.0,x);if(select==0)return base;if(select==1)return base*cos(omega*x);return base*sin(omega*x);}
static double integrate(double omega,int select){double x=0.0,dx=2.0/200.0,value=term(0.0,omega,select)/2.0;int steps=200;if(steps!=1){--steps;while(--steps){x+=dx;value+=term(x,omega,select);}}return(value+term(2.0,omega,select)/2.0)*dx;}
double nbench_fourier_coefficients(const int64_t *input,size_t length){
 if(input==NULL||length<1||length>2)return INVALID_RESULT;int64_t raw=input[0];if(raw<1||raw>MAX_N||length!=1)return INVALID_RESULT;size_t n=(size_t)raw;double a[MAX_N],b[MAX_N];a[0]=integrate(0.0,0)/2.0;b[0]=0.0;
 for(size_t i=1;i<n;i++){double omega=3.1415926535897932*(double)i;a[i]=integrate(omega,1);b[i]=integrate(omega,2);}
 double checksum=0.0;for(size_t i=0;i<n;i++)checksum+=(double)(i+1)*a[i];for(size_t i=1;i<n;i++)checksum+=(double)i*b[i];return isfinite(checksum)?checksum:INVALID_RESULT;
}
