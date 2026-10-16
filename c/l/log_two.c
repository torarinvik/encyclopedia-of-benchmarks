#include <stddef.h>
#include <stdint.h>
int64_t log_two(const int64_t*v,size_t n){if(!v||n!=1||v[0]<0||v[0]>2147483647)return -1;int64_t x=v[0],r=0;while(x>>1){x>>=1;r++;}return r;}
