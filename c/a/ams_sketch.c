#include <stddef.h>
#include <stdint.h>

static void put_i64_le(uint8_t *out,int64_t value){uint64_t u=(uint64_t)value;for(size_t b=0;b<8;++b)out[b]=(uint8_t)(u>>(8*b));}
int64_t ams_sketch(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<4||length>116)return -1;
    int64_t d64=input[0],w64=input[1],k64=input[2],u64=input[3];
    if((d64!=1&&d64!=3&&d64!=5)||w64<1||w64>8||k64<1||k64>8||u64<0||u64>16)return -1;
    size_t d=(size_t)d64,w=(size_t)w64,k=(size_t)k64,u=(size_t)u64,start=4+2*d*k;
    if(length!=start+2*u)return -1;
    for(size_t r=0;r<d;++r)for(size_t key=0;key<k;++key){int64_t bucket=input[4+2*(r*k+key)],sign=input[5+2*(r*k+key)];if(bucket<0||bucket>=w||(sign!=-1&&sign!=1))return -1;}
    for(size_t i=0;i<u;++i){int64_t key=input[start+2*i],weight=input[start+2*i+1];if(key<0||key>=k||weight< -1000||weight>1000)return -1;}
    int64_t counters[5][8]={{0}},estimates[5]={0};
    for(size_t i=0;i<u;++i){size_t key=(size_t)input[start+2*i];int64_t weight=input[start+2*i+1];for(size_t r=0;r<d;++r){size_t pos=4+2*(r*k+key);size_t bucket=(size_t)input[pos];int64_t sign=input[pos+1];counters[r][bucket]+=weight*sign;}}
    for(size_t r=0;r<d;++r)for(size_t b=0;b<w;++b)estimates[r]+=counters[r][b]*counters[r][b];
    for(size_t i=1;i<d;++i){int64_t x=estimates[i];size_t j=i;while(j>0&&estimates[j-1]>x){estimates[j]=estimates[j-1];--j;}estimates[j]=x;}
    if(capacity<8||output==NULL)return -2;put_i64_le(output,estimates[d/2]);return 8;
}
