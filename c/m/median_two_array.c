#include <stddef.h>
#include <stdint.h>
#define BAD (-1.0e300)
double median_two_array(const int64_t*a,size_t len){if(!a||len<2||len>259)return BAD;if(a[0]<0||a[1]<0||a[0]+a[1]<1||a[0]+a[1]>256||(size_t)(a[0]+a[1])+2!=len)return BAD;size_t n=(size_t)(a[0]+a[1]),n1=(size_t)a[0];int64_t v[256];for(size_t i=0;i<n;i++){if(a[i+2]<-1000000||a[i+2]>1000000)return BAD;v[i]=a[i+2];if(i<n1&&i>0&&v[i]<v[i-1])return BAD;if(i>=n1&&i>n1&&v[i]<v[i-1])return BAD;}for(size_t i=1;i<n;i++){int64_t x=v[i];size_t j=i;while(j&&v[j-1]>x){v[j]=v[j-1];j--;}v[j]=x;}size_t m=n/2;return n%2?(double)v[m]:((double)v[m-1]+(double)v[m])/2.0;}
