/* Portable signed-32-bit wave arrangement. */
#include <stddef.h>
#include <stdint.h>
#define MAX_ARRAY_LENGTH 4096
static void sift_down(int64_t *v, size_t root, size_t end) {
    while (root < end/2) { size_t child=root*2+1; if(child+1<end && v[child]<v[child+1]) ++child; if(v[root]>=v[child]) break; int64_t t=v[root];v[root]=v[child];v[child]=t;root=child; }
}

int64_t wave_sort(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity) {
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == NULL)) return -1;
    int64_t values[MAX_ARRAY_LENGTH];
    for (size_t i=0; i<length; ++i) { if (input[i] < INT32_MIN || input[i] > INT32_MAX) return -1; values[i]=input[i]; }
    size_t bytes=length*4;
    if (output_capacity < bytes || (bytes != 0 && output == NULL)) return -2;
        for(size_t start=length/2;start>0;){--start;sift_down(values,start,length);}
    for(size_t end=length;end>1;){int64_t t=values[0];values[0]=values[end-1];values[end-1]=t;--end;sift_down(values,0,end);}
    for(size_t i=0;i+1<length;i+=2){int64_t t=values[i];values[i]=values[i+1];values[i+1]=t;}

    for (size_t i=0; i<length; ++i) { uint32_t bits=(uint32_t)(int32_t)values[i]; for(size_t b=0;b<4;++b) output[i*4+b]=(uint8_t)(bits>>(b*8)); }
    return (int64_t)length;
}
