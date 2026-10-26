#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *out,size_t off,int64_t x){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;++b)out[off+b]=(uint8_t)(u>>(8*b));}
int64_t first_fit_bin_packing(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<1||length>65)return -1;
    int64_t n64=input[0];if(n64<0||n64>64||length!=1+(size_t)n64)return -1;
    size_t n=(size_t)n64;for(size_t i=0;i<n;++i)if(input[i+1]<1||input[i+1]>1000000)return -1;
    int64_t loads[64]={0},assignment[64]={0};size_t bins=0;
    for(size_t i=0;i<n;++i){int64_t size=input[i+1];size_t b=0;while(b<bins&&loads[b]+size>1000000)++b;if(b==bins){loads[b]=size;++bins;}else loads[b]+=size;assignment[i]=(int64_t)b;}
    size_t required=(n+1)*8;if(capacity<required||output==NULL)return -2;
    put_i64_le(output,0,(int64_t)bins);for(size_t i=0;i<n;++i)put_i64_le(output,8*(i+1),assignment[i]);return (int64_t)required;
}
