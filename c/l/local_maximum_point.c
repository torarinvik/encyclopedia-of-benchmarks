#include <stddef.h>
#include <stdint.h>
int64_t local_maximum_point(const int64_t*v,size_t n){if(!v||n<1||n>64)return -1;for(size_t i=0;i<n;i++)if(v[i]<-1000000||v[i]>1000000)return -1;size_t s=0,e=n-1;for(;;){size_t m=s+(e-s)/2;if((m==0||v[m-1]<=v[m])&&(m==n-1||v[m+1]<=v[m]))return m;if(m>0&&v[m-1]>v[m])e=m-1;else s=m+1;}}
