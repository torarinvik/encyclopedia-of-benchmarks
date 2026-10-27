#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_STEPS = 8, MAX_INPUT = 76 };
static void put64(uint8_t *out,size_t offset,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[offset+b]=(uint8_t)(bits&255U);bits>>=8;}}

int64_t distributed_coupon_collection_replay(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<4||length>MAX_INPUT)return -1;
    int64_t n64=input[0],c64=input[1],copies=input[2],steps64=input[3];
    if(n64<2||n64>8||c64<1||c64>8||copies<1||copies>n64||steps64<1||steps64>MAX_STEPS||length!=4+(size_t)n64+(size_t)n64*(size_t)steps64)return -1;
    size_t n=(size_t)n64,coupons=(size_t)c64,steps=(size_t)steps64;uint64_t full=(UINT64_C(1)<<coupons)-1U;
    uint64_t bins[MAX_N]={0};
    for(size_t b=0;b<n;++b){int64_t raw=input[4+b];if(raw<0||((uint64_t)raw&~full)!=0)return -1;bins[b]=(uint64_t)raw;}
    for(size_t coupon=0;coupon<coupons;++coupon){size_t count=0;for(size_t b=0;b<n;++b)if((bins[b]>>coupon)&1U)++count;if(count<(size_t)copies)return -1;}
    size_t tape_at=4+n;for(size_t i=0;i<n*steps;++i)if(input[tape_at+i]!=0&&input[tape_at+i]!=1)return -1;
    if(output==NULL||capacity<16)return -2;
    uint64_t collected=0;int64_t singleton_steps=0;
    for(size_t step=0;step<steps;++step){size_t open_count=0,opened_bin=0;for(size_t bin=0;bin<n;++bin)if(input[tape_at+step*n+bin]==1){++open_count;opened_bin=bin;}if(open_count==1){++singleton_steps;collected|=bins[opened_bin];}}
    uint8_t staged[16];put64(staged,0,(int64_t)collected);put64(staged,8,singleton_steps);for(size_t i=0;i<16;++i)output[i]=staged[i];return 16;
}
