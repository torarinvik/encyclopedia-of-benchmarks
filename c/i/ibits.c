#include <stddef.h>
#include <stdint.h>
int64_t ibits(const int64_t*v,size_t n){if(!v||n!=1||v[0]<0||v[0]>=9007199254740992LL)return -1;int64_t x=v[0],c=0;while(x){c++;x>>=1;}return c;}
