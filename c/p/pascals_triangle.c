#include <stddef.h>
#include <stdint.h>
#define MOD 1000000007LL
int64_t pascals_triangle(const int64_t*v,size_t n){if(!v||n!=1||v[0]<1||v[0]>31)return -1;int rows=(int)v[0];int64_t a[31]={1};for(int r=1;r<rows;r++){a[r]=1;for(int j=r-1;j>0;j--)a[j]+=a[j-1];}int64_t h=0;for(int i=0;i<rows;i++)h=(h*31+a[i])%MOD;return h;}
