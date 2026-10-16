#include <stddef.h>
#include <stdint.h>
int64_t payback(const int64_t*v,size_t n){if(!v||n<1||n>129||v[0]<0||v[0]>128||n!=(size_t)v[0]+1)return -2;int64_t total=0;for(size_t i=1;i<n;i++){if(v[i]<-1000000||v[i]>1000000)return -2;total+=v[i];if(total>=0)return (int64_t)(i-1);}return -1;}
