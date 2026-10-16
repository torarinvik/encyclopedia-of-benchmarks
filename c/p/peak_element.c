#include <stddef.h>
#include <stdint.h>
static int64_t peak(const int64_t*a,int64_t lo,int64_t hi,int64_t n){int64_t mid=lo+(hi-lo)/2;if((mid==0||a[mid-1]<=a[mid])&&(mid==n-1||a[mid+1]<=a[mid]))return mid;if(mid>0&&a[mid-1]>a[mid])return peak(a,lo,mid-1,n);return peak(a,mid+1,hi,n);}
int64_t peak_element(const int64_t*v,size_t n){if(!v||n<2||n>129||v[0]<1||v[0]>128||n!=(size_t)v[0]+1)return -1;int64_t count=v[0];for(int64_t i=0;i<count;i++)if(v[i+1]<-2147483648LL||v[i+1]>2147483647LL)return -1;return peak(v+1,0,count-1,count);}
