#include <stddef.h>
#include <stdint.h>
#define BAD -1
static uint32_t byte(uint32_t h,uint8_t b){return (h^b)*16777619u;}
static uint32_t val(uint32_t h,int64_t x){uint32_t u=(uint32_t)(int32_t)x;for(unsigned s=0;s<32;s+=8)h=byte(h,(uint8_t)(u>>s));return h;}
int64_t print_amatrix_in_spiral_order(const int64_t*v,size_t n){if(!v||n<3||n>66||v[0]<1||v[0]>8||v[1]<1||v[1]>8||n!=2+(size_t)v[0]*(size_t)v[1])return BAD;size_t rows=(size_t)v[0],cols=(size_t)v[1];for(size_t i=2;i<n;i++)if(v[i]<INT32_MIN||v[i]>INT32_MAX)return BAD;size_t t=0,b=rows-1,l=0,r=cols-1;uint32_t h=2166136261u;while(t<=b&&l<=r){for(size_t c=l;c<=r;c++)h=val(h,v[2+t*cols+c]);t++;for(size_t y=t;y<=b;y++)h=val(h,v[2+y*cols+r]);if(r==0)break;r--;if(t<=b){for(size_t c=r+1;c>l;c--)h=val(h,v[2+b*cols+c-1]);if(b==0)break;b--;}if(l<=r){for(size_t y=b+1;y>t;y--)h=val(h,v[2+(y-1)*cols+l]);l++;}}return (int64_t)h;}
