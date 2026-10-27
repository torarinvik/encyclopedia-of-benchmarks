#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_H = 8, MAX_INPUT = 82, MAX_OUTPUT = 72 };
static const int64_t INPUT_SCALE = INT64_C(1000000);
static void put64(uint8_t *out,size_t at,int64_t value){uint64_t bits=(uint64_t)value;for(size_t b=0;b<8;++b){out[at+b]=(uint8_t)(bits&255U);bits>>=8;}}
static int64_t gcd64(int64_t a,int64_t b){while(b!=0){int64_t r=a%b;a=b;b=r;}return a;}

int64_t sensor_energy_balance_estimator_trace(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
    if(input==NULL||length<4||length>MAX_INPUT)return -1;
    int64_t n64=input[0],h64=input[1];
    if(n64<1||n64>MAX_N||h64<1||h64>MAX_H||length!=2+(size_t)n64+(size_t)h64+(size_t)n64*(size_t)h64)return -1;
    size_t n=(size_t)n64,h=(size_t)h64;int64_t sum=0;int64_t lambda[MAX_N]={0};
    for(size_t i=0;i<n;++i){lambda[i]=input[2+i];if(lambda[i]<0||lambda[i]>INPUT_SCALE)return -1;sum+=lambda[i];}
    if(sum!=INPUT_SCALE)return -1;
    uint64_t full=(UINT64_C(1)<<n)-1U;size_t path_at=2+n;
    for(size_t t=0;t<h;++t){int64_t mask=input[path_at+t];if(mask<=0||((uint64_t)mask&~full)!=0)return -1;}
    int64_t lcm=1;for(int64_t t=2;t<=h64;++t)lcm=(lcm/gcd64(lcm,t))*t;
    int64_t q=INPUT_SCALE*lcm;size_t draw_at=path_at+h;
    for(size_t i=0;i<n*h;++i)if(input[draw_at+i]<0||input[draw_at+i]>=q)return -1;
    int64_t state[MAX_N]={0};for(size_t i=0;i<n;++i)state[i]=lambda[i]*lcm;
    for(size_t t=0;t<h;++t){int64_t divisor=(int64_t)t+1,delta=q/divisor;uint64_t path=(uint64_t)input[path_at+t];for(size_t i=0;i<n;++i){if(state[i]<0||state[i]>q)return -1;int64_t r=input[draw_at+t*n+i]<state[i]?1:0;int64_t x=(int64_t)((path>>i)&1U);int64_t updated=state[i]+(x-r)*delta;if(updated<0||updated>q)return -1;state[i]=updated;}}
    size_t bytes=8*(1+n);if(output==NULL||capacity<bytes)return -2;uint8_t staged[MAX_OUTPUT];put64(staged,0,q);for(size_t i=0;i<n;++i)put64(staged,8*(i+1),state[i]);for(size_t i=0;i<bytes;++i)output[i]=staged[i];return (int64_t)bytes;
}
