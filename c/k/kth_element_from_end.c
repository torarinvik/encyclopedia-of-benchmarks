#include <stddef.h>
#include <stdint.h>
int64_t kth_element_from_end(const int64_t*v,size_t n){if(!v||n<1||n>65)return -1;int64_t k=v[0];if(k<=0||k>=n)return -1;for(size_t i=1;i<n;i++)if(v[i]<0||v[i]>100000)return -1;return v[n-(size_t)k];}
