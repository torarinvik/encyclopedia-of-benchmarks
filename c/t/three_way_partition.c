#include <stddef.h>
#include <stdint.h>
#include <string.h>
#define MAX_COUNT 256
int64_t three_way_partition(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > MAX_COUNT + 2) return -1;
    int64_t n = input[0], pivot = input[1];
    if (n < 0 || n > MAX_COUNT || length != (size_t)n + 2 || pivot < INT32_MIN || pivot > INT32_MAX) return -1;
    int32_t a[MAX_COUNT];
    for (size_t i=0;i<(size_t)n;i++) { if(input[i+2]<INT32_MIN||input[i+2]>INT32_MAX)return -1; a[i]=(int32_t)input[i+2]; }
    size_t low=0, mid=0, high=(size_t)n;
    while(mid<high) { if(a[mid]<pivot){int32_t t=a[low];a[low++]=a[mid];a[mid++]=t;} else if(a[mid]>pivot){int32_t t=a[mid];a[mid]=a[--high];a[high]=t;} else mid++; }
    size_t bytes=((size_t)n+2)*4; if(capacity<bytes||!output)return -2;
    for(size_t i=0;i<(size_t)n;i++) memcpy(output+4*i,&a[i],4);
    int32_t bounds[2]={(int32_t)low,(int32_t)high}; memcpy(output+4*(size_t)n,bounds,8);
    return n+2;
}
