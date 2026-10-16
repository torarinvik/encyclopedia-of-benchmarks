#include <stddef.h>
#include <stdint.h>
int64_t percentage(const int64_t*v,size_t n){if(!v||n!=3||v[0]<1||v[0]>100000||v[1]<1||v[1]>100000||v[2]<1||v[2]>4)return -1;int64_t scale=1;for(int64_t i=0;i<v[2];i++)scale*=10;int64_t product=v[0]*v[1]*scale;if(product<100)return -1;return product/100;}
