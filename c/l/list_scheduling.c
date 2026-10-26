#include <stddef.h>
#include <stdint.h>

#define MAX_M 8
#define MAX_N 32
#define MAX_INPUT 34
static void put64(uint8_t *o, size_t p, int64_t x) { uint64_t b=(uint64_t)x; for(size_t j=0;j<8;++j){o[p+j]=(uint8_t)(b&255U);b>>=8;} }

int64_t list_scheduling(const int64_t *in,size_t len,uint8_t *out,size_t cap){
    if(!in||len<3||len>MAX_INPUT)return -1;
    int64_t m64=in[0],n64=in[1];
    if(m64<1||m64>MAX_M||n64<1||n64>MAX_N||len!=(size_t)(2+n64))return -1;
    size_t m=(size_t)m64,n=(size_t)n64;
    for(size_t i=0;i<n;++i)if(in[2+i]<1||in[2+i]>10000)return -1;
    size_t bytes=8*(1+n+m); if(!out||cap<bytes)return -2;
    int64_t load[MAX_M]={0},assign[MAX_N];
    for(size_t i=0;i<n;++i){size_t best=0;for(size_t j=1;j<m;++j)if(load[j]<load[best])best=j;assign[i]=(int64_t)best;load[best]+=in[2+i];}
    int64_t makespan=load[0];for(size_t j=1;j<m;++j)if(load[j]>makespan)makespan=load[j];
    put64(out,0,makespan);for(size_t i=0;i<n;++i)put64(out,8*(1+i),assign[i]);for(size_t j=0;j<m;++j)put64(out,8*(1+n+j),load[j]);
    return (int64_t)bytes;
}
