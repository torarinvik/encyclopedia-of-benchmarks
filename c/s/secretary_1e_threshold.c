#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_INPUT 17
static const int sample_count[MAX_N+1]={0,0,0,1,1,1,2,2,2,3,3,4,4,4,5,5,5};
static void put64(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t j=0;j<8;++j){out[at+j]=(uint8_t)(bits&255U);bits>>=8;}}

int64_t secretary_1e_threshold(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<4||length>MAX_INPUT)return -1;
    int64_t n64=input[0];if(n64<3||n64>MAX_N||length!=(size_t)n64+1)return -1;size_t n=(size_t)n64;
    uint8_t seen[MAX_N+1]={0};for(size_t i=0;i<n;++i){int64_t rank=input[i+1];if(rank<1||rank>n64||seen[rank])return -1;seen[rank]=1;}
    size_t observed=(size_t)sample_count[n];int64_t threshold=input[1];for(size_t i=1;i<observed;++i)if(input[1+i]>threshold)threshold=input[1+i];
    int64_t selected=-1;for(size_t i=observed;i<n;++i)if(input[1+i]>threshold){selected=(int64_t)i;break;}
    if(!output||capacity<8)return -2;uint8_t staged[8];put64(staged,0,selected);for(size_t i=0;i<8;++i)output[i]=staged[i];return 8;
}
