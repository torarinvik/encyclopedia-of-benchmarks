#include <stddef.h>
#include <stdint.h>
#define MAX_COUNT 64
static uint32_t mix(uint32_t h, uint8_t b) { return (h ^ b) * 16777619u; }
static uint32_t feed(uint32_t h, uint32_t x) { for (unsigned s=0;s<32;s+=8) h=mix(h,(uint8_t)(x>>s)); return h; }
int64_t pack_consecutive_repetitions_in_sublist(const int64_t *v, size_t n) {
    if (!v || n<1 || n>MAX_COUNT+1 || v[0]<0 || v[0]>MAX_COUNT || n!=(size_t)v[0]+1) return -1;
    size_t count=(size_t)v[0];
    for(size_t i=0;i<count;i++) if(v[i+1]<INT32_MIN||v[i+1]>INT32_MAX) return -1;
    uint32_t h=2166136261u;
    for(size_t i=0;i<count;){
        int32_t value=(int32_t)v[i+1]; size_t j=i+1;
        while(j<count && v[j+1]==value) j++;
        h=feed(h,(uint32_t)value); h=feed(h,(uint32_t)(j-i)); i=j;
    }
    return (int64_t)h;
}
