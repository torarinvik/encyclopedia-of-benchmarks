#include <stddef.h>
#include <stdint.h>
static const char empty[]="       ...       ....        nothing printing :(";
static size_t run(uint8_t*o,size_t p,uint8_t b,size_t n){while(n--){o[p++]=b;}return p;}
int64_t magicdiamondpattern(int64_t n,uint8_t*out,size_t cap){if(n>45)return -1;if(n<=0){size_t z=sizeof(empty)-1;if(!out||cap<z)return -2;for(size_t i=0;i<z;i++)out[i]=(uint8_t)empty[i];return (int64_t)z;}size_t s=(size_t)n,need=3*s*s+4*s;if(!out||cap<need)return -2;size_t p=0;for(size_t i=0;i<s;i++){p=run(out,p,' ',s-i-1);for(size_t j=0;j<i+1;j++){out[p++]='*';out[p++]=' ';}out[p++]='\n';}for(size_t i=s;i>0;i--){for(size_t j=0;j<i;j++){out[p++]='*';out[p++]=' ';}out[p++]='\n';p=run(out,p,' ',s-i+1);}return (int64_t)p;}
