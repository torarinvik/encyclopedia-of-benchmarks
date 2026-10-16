#include <stddef.h>
#include <stdint.h>
int64_t length_of_list(const int64_t*v,size_t n){if(n>64)return -1;for(size_t i=0;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return (int64_t)n;}
