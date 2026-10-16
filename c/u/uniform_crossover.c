#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *output, size_t offset, int64_t value) { uint64_t bits=(uint64_t)value; for(size_t byte=0;byte<8;++byte) output[offset+byte]=(uint8_t)(bits>>(8*byte)); }

int64_t uniform_crossover(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(input==NULL||length<4||length>193)return -1;
    int64_t n=input[0];if(n<1||n>64||length!=(size_t)(1+3*n))return -1;
    for(size_t i=0;i<(size_t)n;++i)if(input[1+i]!=0&&input[1+i]!=1)return -1;
    for(size_t i=0;i<2*(size_t)n;++i)if(input[1+(size_t)n+i]<INT64_C(-2147483648)||input[1+(size_t)n+i]>INT64_C(2147483647))return -1;
    size_t count=(size_t)n,bytes=16*count;if(output==NULL||capacity<bytes)return -2;
    for(size_t i=0;i<count;++i){int64_t a=input[1+i],p=input[1+count+i],q=input[1+2*count+i];int64_t c1=a?p:q,c2=a?q:p;put_i64_le(output,i*8,c1);put_i64_le(output,(count+i)*8,c2);}
    return (int64_t)bytes;
}
