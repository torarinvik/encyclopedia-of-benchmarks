#include <stddef.h>
#include <stdint.h>
int64_t xtea(const int64_t *input,size_t length,uint8_t *output,size_t capacity){
 if(!input||length!=25||input[0]<1||input[0]>64)return -1;for(size_t i=1;i<25;i++)if(input[i]<0||input[i]>255)return -1;if(!output||capacity<8)return -2;
 uint32_t v0=0,v1=0,k[4]={0,0,0,0};for(int i=0;i<4;i++){v0=(v0<<8)|(uint32_t)input[1+i];v1=(v1<<8)|(uint32_t)input[5+i];for(int j=0;j<4;j++)k[i]=(k[i]<<8)|(uint32_t)input[9+i*4+j];}
 uint32_t sum=0,delta=UINT32_C(0x9E3779B9);for(int64_t r=0;r<input[0];r++){v0+=( ((v1<<4 ^ v1>>5)+v1) ^ (sum+k[sum&3]) );sum+=delta;v1+=( ((v0<<4 ^ v0>>5)+v0) ^ (sum+k[(sum>>11)&3]) );}
 for(int i=0;i<4;i++){output[i]=(uint8_t)(v0>>(24-8*i));output[4+i]=(uint8_t)(v1>>(24-8*i));}return 8;
}
