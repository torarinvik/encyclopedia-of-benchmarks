#include <stddef.h>
#include <stdint.h>
#define MAX_COUNT 6
static uint32_t mix(uint32_t h,uint8_t b){return (h^b)*16777619u;}
static int next_perm(int32_t*a,size_t n){size_t i=n-1;while(i>0&&a[i-1]>=a[i])i--;if(i==0)return 0;size_t j=n-1;while(a[j]<=a[i-1])j--;int32_t t=a[i-1];a[i-1]=a[j];a[j]=t;for(size_t l=i,r=n-1;l<r;l++,r--){t=a[l];a[l]=a[r];a[r]=t;}return 1;}
int64_t permutations(const int64_t*v,size_t n){if(!v||n<2||n>MAX_COUNT+1||v[0]<1||v[0]>MAX_COUNT||n!=(size_t)v[0]+1)return -1;size_t count=(size_t)v[0];int32_t a[MAX_COUNT];for(size_t i=0;i<count;i++){if(v[i+1]<INT32_MIN||v[i+1]>INT32_MAX)return -1;a[i]=(int32_t)v[i+1];if(i>0&&a[i-1]>=a[i])return -1;}uint32_t h=2166136261u;do{for(size_t i=0;i<count;i++){uint32_t u=(uint32_t)a[i];for(unsigned b=0;b<4;b++)h=mix(h,(uint8_t)(u>>(8*b)));}h=mix(h,255);}while(next_perm(a,count));return (int64_t)h;}
