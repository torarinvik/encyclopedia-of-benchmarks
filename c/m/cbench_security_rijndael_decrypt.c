#include <stddef.h>
#include <stdint.h>
#include <string.h>

enum { KEY_BYTES=32, BLOCK_BYTES=16, INPUT_BYTES=48 };
static uint8_t mul(uint8_t a,uint8_t b){uint8_t r=0;while(b){if(b&1)r^=a;a=(uint8_t)((a<<1)^((a&128)?0x1b:0));b>>=1;}return r;}
static uint8_t pow_gf(uint8_t a,unsigned n){uint8_t r=1;while(n){if(n&1)r=mul(r,a);a=mul(a,a);n>>=1;}return r;}
static uint8_t rot8(uint8_t a,unsigned n){return (uint8_t)((a<<n)|(a>>(8-n)));}
static void boxes(uint8_t s[256],uint8_t inv[256]){for(unsigned x=0;x<256;x++){uint8_t q=x?pow_gf((uint8_t)x,254):0;s[x]=(uint8_t)(q^rot8(q,1)^rot8(q,2)^rot8(q,3)^rot8(q,4)^0x63);}for(unsigned x=0;x<256;x++)inv[s[x]]=(uint8_t)x;}
static void decrypt_block(const uint8_t key[32],const uint8_t in[16],uint8_t out[16]){
 uint8_t s[256],inv[256],rk[240],state[16];static const uint8_t rc[7]={1,2,4,8,16,32,64};boxes(s,inv);memcpy(rk,key,32);
 size_t w=32;while(w<240){unsigned wi=(unsigned)(w/4);uint8_t t[4];for(unsigned j=0;j<4;j++)t[j]=rk[w-4+j];if(wi%8==0){uint8_t a=t[0];t[0]=s[t[1]]^rc[wi/8-1];t[1]=s[t[2]];t[2]=s[t[3]];t[3]=s[a];}else if(wi%8==4){for(unsigned j=0;j<4;j++)t[j]=s[t[j]];}for(unsigned j=0;j<4;j++){rk[w]=rk[w-32]^t[j];w++;}}
 memcpy(state,in,16);for(unsigned i=0;i<16;i++)state[i]^=rk[224+i];
 for(int round=13;round>0;round--){uint8_t prev[16];memcpy(prev,state,16);for(unsigned c=0;c<4;c++)for(unsigned r=0;r<4;r++)state[r+4*c]=inv[prev[r+4*((c+4-r)%4)]];for(unsigned i=0;i<16;i++)state[i]^=rk[round*16+i];for(unsigned c=0;c<4;c++){unsigned o=4*c;uint8_t a=state[o],b=state[o+1],d=state[o+2],e=state[o+3];state[o]=mul(a,14)^mul(b,11)^mul(d,13)^mul(e,9);state[o+1]=mul(a,9)^mul(b,14)^mul(d,11)^mul(e,13);state[o+2]=mul(a,13)^mul(b,9)^mul(d,14)^mul(e,11);state[o+3]=mul(a,11)^mul(b,13)^mul(d,9)^mul(e,14);}}
 uint8_t prev[16];memcpy(prev,state,16);for(unsigned c=0;c<4;c++)for(unsigned r=0;r<4;r++)state[r+4*c]=inv[prev[r+4*((c+4-r)%4)]];for(unsigned i=0;i<16;i++)out[i]=state[i]^rk[i];
}
int64_t cbench_security_rijndael_decrypt(const int64_t *values,size_t length,uint8_t *output,size_t capacity){if(!values||length!=INPUT_BYTES)return -1;for(size_t i=0;i<INPUT_BYTES;i++)if(values[i]<0||values[i]>255)return -1;if(!output||capacity<BLOCK_BYTES)return -2;uint8_t key[32],block[16],plain[16];for(size_t i=0;i<32;i++)key[i]=(uint8_t)values[i];for(size_t i=0;i<16;i++)block[i]=(uint8_t)values[32+i];decrypt_block(key,block,plain);memcpy(output,plain,16);return 16;}
