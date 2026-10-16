#include <stddef.h>
#include <stdint.h>
int64_t local_binary_pattern(const int64_t*v,size_t n){if(!v||n!=9)return -1;for(size_t i=0;i<9;i++)if(v[i]<0||v[i]>255)return -1;const size_t ix[8]={2,5,1,8,7,6,3,0};int64_t out=0;for(size_t i=0;i<8;i++)if(v[ix[i]]>=v[4])out|=(int64_t)1<<i;return out;}
