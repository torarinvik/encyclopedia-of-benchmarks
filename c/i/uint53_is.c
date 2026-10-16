#include <stddef.h>
#include <stdint.h>
int64_t uint53_is(const int64_t*v,size_t n){if(!v||n!=1)return -1;return v[0]>=0&&v[0]<9007199254740992LL?1:0;}
