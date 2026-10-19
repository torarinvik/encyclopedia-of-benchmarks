/* ANSIbench LINPACK dgefa/dgesl profile; source and stated modifications are public domain. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>
#define INVALID_RESULT (-1e300)

static void daxpy_r(int n,double factor,const double *x,double *y){if(n<=0||factor==0.0)return;for(int i=0;i<n;i++)y[i]=y[i]+factor*x[i];}
static int dgefa(double *a,int n,int *ipvt){int info=0,nm1=n-1;if(nm1>=0)for(int k=0;k<nm1;k++){int kp1=k+1,l=k;double maximum=fabs(a[n*k+k]);for(int i=1;i<n-k;i++){double candidate=fabs(a[n*k+k+i]);if(candidate>maximum){l=k+i;maximum=candidate;}}ipvt[k]=l;if(a[n*k+l]!=0.0){if(l!=k){double t=a[n*k+l];a[n*k+l]=a[n*k+k];a[n*k+k]=t;}double t=-1.0/a[n*k+k];for(int i=0;i<n-(k+1);i++)a[n*k+k+1+i]=t*a[n*k+k+1+i];for(int j=kp1;j<n;j++){t=a[n*j+l];if(l!=k){a[n*j+l]=a[n*j+k];a[n*j+k]=t;}daxpy_r(n-(k+1),t,&a[n*k+k+1],&a[n*j+k+1]);}}else info=k;}ipvt[n-1]=n-1;if(a[n*(n-1)+(n-1)]==0.0)info=n-1;return info;}
static void dgesl(const double *a,int n,const int *ipvt,double *b){int nm1=n-1;if(nm1>=1)for(int k=0;k<nm1;k++){int l=ipvt[k];double t=b[l];if(l!=k){b[l]=b[k];b[k]=t;}daxpy_r(n-(k+1),t,&a[n*k+k+1],&b[k+1]);}for(int kb=0;kb<n;kb++){int k=n-(kb+1);b[k]=b[k]/a[n*k+k];double t=-b[k];daxpy_r(k,t,&a[n*k],&b[0]);}}

double linpack_lu_solve(const int64_t *input,size_t length){if(!input||length<1||length>22)return INVALID_RESULT;int64_t raw_n=input[0];if(raw_n<2||raw_n>4)return INVALID_RESULT;int n=(int)raw_n;if(length!=(size_t)(1+n*n+n))return INVALID_RESULT;double a[16]={0},b[4]={0};int ipvt[4]={0};for(int i=0;i<n*n;i++){int64_t value=input[1+i];if(value< -8||value>8)return INVALID_RESULT;a[i]=(double)value;}for(int i=0;i<n;i++){int64_t value=input[1+n*n+i];if(value< -32||value>32)return INVALID_RESULT;b[i]=(double)value;}int info=dgefa(a,n,ipvt);if(info!=0)return INVALID_RESULT;dgesl(a,n,ipvt,b);double result=0.0;for(int i=0;i<n;i++)result+=(double)(i+1)*b[i];return isfinite(result)?result:INVALID_RESULT;}
