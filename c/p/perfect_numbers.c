#include <stddef.h>
#include <stdint.h>
int64_t perfect_numbers(const int64_t*v,size_t n){if(!v||n!=1||v[0]<0||v[0]>1000000000)return -1;int64_t x=v[0];if(x<=1)return 0;int64_t sum=1;for(int64_t d=2;d<=x/d;d++)if(x%d==0){sum+=d;if(d!=x/d)sum+=x/d;}return sum==x;}
