/* Copyright 2018 Embedded Microprocessor Benchmark Consortium (EEMBC).
 * Apache-2.0 licensed upstream kernel, bounded variant; modifications made. */
#include <stddef.h>
#include <stdint.h>

#define N 3
static uint16_t crc_byte(uint8_t value, uint16_t crc) {
    for (unsigned bit=0; bit<8; ++bit) {
        uint16_t mix=(uint16_t)((value&1u)^(crc&1u)); value>>=1;
        if (mix) crc^=0x4002u;
        crc>>=1;
        if (mix) crc|=0x8000u; else crc&=0x7fffu;
    }
    return crc;
}
static uint16_t crc16(int16_t value, uint16_t crc) {
    uint16_t bits=(uint16_t)value;
    crc=crc_byte((uint8_t)bits,crc);
    return crc_byte((uint8_t)(bits>>8),crc);
}
static int16_t matrix_sum(const int32_t *c, int16_t clipval) {
    int32_t tmp=0,prev=0,cur=0; int16_t ret=0;
    for (int i=0;i<N*N;++i) {
        cur=c[i]; tmp+=cur;
        if (tmp>clipval) { ret=(int16_t)(ret+10); tmp=0; }
        else if (cur>prev) ret=(int16_t)(ret+1);
        prev=cur;
    }
    return ret;
}
static void put_i64(uint8_t *out,size_t offset,int64_t value) {
    uint64_t bits=(uint64_t)value;
    for(size_t b=0;b<8;++b) out[offset+b]=(uint8_t)(bits>>(8*b));
}

int64_t coremark_matrix_manipulation(const int64_t *input,size_t length,uint8_t *output,size_t capacity) {
    if(input==NULL||length!=19) return -1;
    int64_t rawval=input[0];
    if(rawval<0||rawval>15) return -1;
    int16_t a[N*N],original[N*N],b[N*N];
    for(int i=0;i<N*N;++i) {
        if(input[1+i]<0||input[1+i]>127||input[10+i]<0||input[10+i]>127) return -1;
        a[i]=original[i]=(int16_t)input[1+i]; b[i]=(int16_t)input[10+i];
    }
    if(output==NULL||capacity<112) return -2;
    const int16_t value=(int16_t)rawval;
    const int16_t clipval=(int16_t)(value-4096);
    int16_t sums[4]; int32_t c[N*N];
    for(int i=0;i<N*N;++i) a[i]=(int16_t)(a[i]+value);
    for(int i=0;i<N*N;++i) c[i]=(int32_t)a[i]*(int32_t)value;
    sums[0]=matrix_sum(c,clipval);
    for(int i=0;i<N;++i){c[i]=0;for(int j=0;j<N;++j)c[i]+=(int32_t)a[i*N+j]*(int32_t)b[j];}
    sums[1]=matrix_sum(c,clipval);
    for(int i=0;i<N;++i)for(int j=0;j<N;++j){c[i*N+j]=0;for(int k=0;k<N;++k)c[i*N+j]+=(int32_t)a[i*N+k]*(int32_t)b[k*N+j];}
    sums[2]=matrix_sum(c,clipval);
    for(int i=0;i<N;++i)for(int j=0;j<N;++j){c[i*N+j]=0;for(int k=0;k<N;++k){int32_t t=(int32_t)a[i*N+k]*(int32_t)b[k*N+j];c[i*N+j]+=((t>>2)&0xf)*((t>>5)&0x7f);}}
    sums[3]=matrix_sum(c,clipval);
    uint16_t crc=0;for(int i=0;i<4;++i)crc=crc16(sums[i],crc);
    for(int i=0;i<N*N;++i)a[i]=(int16_t)(a[i]-value);
    int64_t result[14];result[0]=crc;for(int i=0;i<4;++i)result[i+1]=sums[i];for(int i=0;i<N*N;++i)result[i+5]=a[i];
    for(size_t i=0;i<14;++i)put_i64(output,i*8,result[i]);
    return 112;
}
