#include <stddef.h>
#include <stdint.h>
static void put_i64_le(uint8_t*out,size_t p,int64_t x){uint64_t u=(uint64_t)x;for(size_t b=0;b<8;++b)out[p+b]=(uint8_t)(u>>(8*b));}
int64_t deterministic_line_search(const int64_t*input,size_t length,uint8_t*output,size_t capacity){
 if(input==NULL||length!=1)return -1;int64_t target=input[0];if(target==0||target< -50000||target>50000)return -1;
 int64_t distance=target<0?-target:target,traveled=0,leg=0,depth=1;
 for(;;){int negative=(leg%2)==0;if((target<0)==negative&&distance<=depth){traveled+=distance;break;}traveled+=2*depth;depth*=2;leg++;}
 if(capacity<16||output==NULL)return -2;put_i64_le(output,0,traveled);put_i64_le(output,8,leg);return 16;
}
