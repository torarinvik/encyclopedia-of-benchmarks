#include <stddef.h>
#include <stdint.h>
int64_t kth_element_in_a_list(const int64_t*v,size_t n){if(n<3||n>34)return -1;int64_t k=v[0],pos=v[1];if(k<1||k>16||n!=(size_t)(k+2)||pos<1||pos>k)return -1;for(int64_t i=0;i<k;i++)if(v[i+2]<-10000||v[i+2]>10000)return -1;return v[pos+1];}
