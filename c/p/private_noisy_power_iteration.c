#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_N 4
#define MAX_L 4
#define MAX_INPUT 39

static int64_t trunc_div(int64_t numerator, int64_t denominator) {
    return numerator < 0 ? -((-numerator) / denominator) : numerator / denominator;
}
static int64_t floor_sqrt(int64_t value) {
    int64_t low=0, high=INT64_C(13000001);
    while(low+1<high){int64_t middle=(low+high)/2;if(middle<=value/middle)low=middle;else high=middle;}
    return low;
}
static void put64(uint8_t *out,size_t pos,int64_t value){uint64_t bits=(uint64_t)value;for(size_t j=0;j<8;++j){out[pos+j]=(uint8_t)(bits&255U);bits>>=8;}}

int64_t private_noisy_power_iteration(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(!input||length<11||length>MAX_INPUT)return -1;
    int64_t n64=input[0],l64=input[1],sigma=input[2];
    if(n64<2||n64>MAX_N||l64<1||l64>MAX_L||sigma<0||sigma>SCALE||length!=3+(size_t)n64*(size_t)n64+(size_t)n64+(size_t)l64*(size_t)n64)return -1;
    size_t n=(size_t)n64,rounds=(size_t)l64,matrix_start=3,vector_start=3+n*n,noise_start=vector_start+n;
    int64_t matrix[MAX_N*MAX_N],x[MAX_N],noise[MAX_L*MAX_N];
    for(size_t i=0;i<n*n;++i){matrix[i]=input[matrix_start+i];if(matrix[i]<-SCALE||matrix[i]>SCALE)return -1;}
    for(size_t i=0;i<n;++i)for(size_t j=0;j<n;++j)if(matrix[i*n+j]!=matrix[j*n+i])return -1;
    int64_t initial_norm=0;
    for(size_t i=0;i<n;++i){x[i]=input[vector_start+i];if(x[i]<-SCALE||x[i]>SCALE)return -1;initial_norm+=x[i]*x[i];}
    if(initial_norm!=SCALE*SCALE)return -1;
    for(size_t i=0;i<rounds*n;++i){noise[i]=input[noise_start+i];if(noise[i]<-2*SCALE||noise[i]>2*SCALE)return -1;}
    int64_t y[MAX_N];
    for(size_t step=0;step<rounds;++step){
        int64_t norm_sq=0;
        for(size_t i=0;i<n;++i){int64_t sum=sigma*noise[step*n+i];for(size_t j=0;j<n;++j)sum+=matrix[i*n+j]*x[j];y[i]=trunc_div(sum,SCALE);norm_sq+=y[i]*y[i];}
        if(norm_sq==0)return -1;
        int64_t radius=floor_sqrt(norm_sq);
        for(size_t i=0;i<n;++i)x[i]=trunc_div(y[i]*SCALE,radius);
    }
    size_t bytes=8*n;if(!output||capacity<bytes)return -2;
    uint8_t staged[8*MAX_N];for(size_t i=0;i<n;++i)put64(staged,8*i,x[i]);
    for(size_t i=0;i<bytes;++i)output[i]=staged[i];
    return (int64_t)bytes;
}
