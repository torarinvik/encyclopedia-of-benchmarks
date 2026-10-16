#include <stddef.h>
#include <stdint.h>
#define MAX_COUNT 64
#define MOD 1000000007LL
#define BASE 2000000003LL
int64_t partition_linked_list(const int64_t*v,size_t n){if(!v||n<2||n>MAX_COUNT+2||v[0]<0||v[0]>MAX_COUNT||n!=(size_t)v[0]+2||v[1]<INT32_MIN||v[1]>INT32_MAX)return -1;size_t count=(size_t)v[0];int64_t less[MAX_COUNT],ge[MAX_COUNT];size_t a=0,b=0;for(size_t i=0;i<count;i++){int64_t x=v[i+2];if(x<INT32_MIN||x>INT32_MAX)return -1;if(x<v[1])less[a++]=x;else ge[b++]=x;}int64_t h=0;for(size_t i=0;i<a;i++)h=(h*BASE+less[i]-INT32_MIN)%MOD;for(size_t i=0;i<b;i++)h=(h*BASE+ge[i]-INT32_MIN)%MOD;return h;}
