#include <stddef.h>
#include <stdint.h>
#define MAX_TAPS 63
#define MAX_CLOCKS 256
static void put_i64(uint8_t *out,size_t slot,int64_t value){uint64_t bits=(uint64_t)value;for(size_t i=0;i<8;++i)out[slot*8+i]=(uint8_t)(bits>>(8*i));}
static uint64_t feedback(uint64_t state,const int64_t*taps,size_t count){uint64_t bit=0;for(size_t i=0;i<count;++i)bit^=(state>>(unsigned)taps[i])&1U;return bit;}
static uint64_t step(uint64_t*state,size_t width,uint64_t mask,const int64_t*taps,size_t count){uint64_t out=(*state>>(width-1))&1U;*state=((*state<<1)|feedback(*state,taps,count))&mask;return out;}
int64_t lfsr(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(!input||length<6||input[0]<1||input[0]>63||input[1]<0||input[1]>=input[0]||input[2]<0||input[2]>MAX_TAPS||input[3]<0||input[3]>MAX_CLOCKS||input[5]<0||input[5]>4194303)return -1;
 size_t width=(size_t)input[0],tap_count=(size_t)input[2],clock_count=(size_t)input[3];if(length!=6+tap_count)return -1;const int64_t*taps=input+6;for(size_t i=0;i<tap_count;++i)if(taps[i]<0||taps[i]>=(int64_t)width)return -1;
 uint64_t mask=(UINT64_C(1)<<width)-1,state=0,key=(uint64_t)input[4],frame=(uint64_t)input[5];for(int bit=63;bit>=0;--bit)state=((state<<1)|((((key>>(unsigned)bit)&1U)^feedback(state,taps,tap_count))&1U))&mask;for(int bit=21;bit>=0;--bit)state=((state<<1)|((((frame>>(unsigned)bit)&1U)^feedback(state,taps,tap_count))&1U))&mask;
 size_t bytes=(clock_count+2)*8;if(!output||capacity<bytes)return -2;put_i64(output,0,(int64_t)clock_count);for(size_t i=0;i<clock_count;++i)put_i64(output,1+i,(int64_t)step(&state,width,mask,taps,tap_count));put_i64(output,1+clock_count,(int64_t)state);return (int64_t)bytes;
}
