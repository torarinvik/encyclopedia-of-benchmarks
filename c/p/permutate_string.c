#include <stddef.h>
#include <stdint.h>
#define MAX_INPUT_LENGTH 8
static void sort_bytes(uint8_t *a,size_t n){for(size_t i=1;i<n;i++){uint8_t x=a[i];size_t j=i;while(j>0&&a[j-1]>x){a[j]=a[j-1];j--;}a[j]=x;}}
static int next_perm(uint8_t*a,size_t n){size_t i=n-1;while(i>0&&a[i-1]>=a[i])i--;if(i==0)return 0;size_t j=n-1;while(a[j]<=a[i-1])j--;uint8_t t=a[i-1];a[i-1]=a[j];a[j]=t;for(size_t l=i,r=n-1;l<r;l++,r--){t=a[l];a[l]=a[r];a[r]=t;}return 1;}
static uint32_t mix(uint32_t h,uint8_t b){return (h^b)*16777619u;}
int64_t permutate_string(const int64_t*v,size_t n){if(!v||n<2||n>MAX_INPUT_LENGTH||v[0]<1||v[0]>7||n!=(size_t)v[0]+1)return -1;size_t len=(size_t)v[0];uint8_t a[7];for(size_t i=0;i<len;i++){if(v[i+1]<33||v[i+1]>126)return -1;a[i]=(uint8_t)v[i+1];for(size_t j=0;j<i;j++)if(a[j]==a[i])return -1;}sort_bytes(a,len);uint32_t h=2166136261u;do{for(size_t i=0;i<len;i++)h=mix(h,a[i]);h=mix(h,0);}while(next_perm(a,len));return (int64_t)h;}
