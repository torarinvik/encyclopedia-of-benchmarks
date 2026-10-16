#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
int64_t largest_divisible_subset(const int64_t*v,size_t n){if((!v&&n)||n>64)return -1;int64_t a[64],d[64];for(size_t i=0;i<n;i++){if(v[i]<1||v[i]>50000)return -1;a[i]=v[i];}for(size_t i=1;i<n;i++){int64_t x=a[i];size_t j=i;while(j&&a[j-1]>x){a[j]=a[j-1];j--;}a[j]=x;}int64_t best=0;for(size_t i=0;i<n;i++){d[i]=1;for(size_t j=0;j<i;j++)if(a[i]%a[j]==0&&d[j]+1>d[i])d[i]=d[j]+1;if(d[i]>best)best=d[i];}return best;}
