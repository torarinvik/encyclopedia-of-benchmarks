#include <stddef.h>
#include <stdint.h>
static int64_t find_peak(const int64_t*a,size_t lo,size_t hi){size_t n=hi-lo,m=n/2;int64_t l=a[lo+m-1],c=a[lo+m],r=a[lo+m+1];if(c>l&&c>r)return c;if(l<r){size_t start=m;if(m==2)start--;return find_peak(a,lo+start,hi);}size_t end=m;if(m==2)end++;return find_peak(a,lo,lo+end);}
int64_t peak(const int64_t*v,size_t n){if(!v||n<4||n>65||v[0]<3||v[0]>64||n!=(size_t)v[0]+1)return -1;size_t len=(size_t)v[0],p=1;for(size_t i=0;i<len;i++)if(v[i+1]<-1000000||v[i+1]>1000000)return -1;while(p<len-1&&v[p+1]>v[p])p++;if(p==1||p>=len-1)return -1;for(size_t i=p;i+1<len;i++)if(v[i+1]>=v[i])return -1;return find_peak(v+1,0,len); }
