#include <stdint.h>
#include <stddef.h>
static uint32_t round_key(uint32_t key,unsigned round){uint32_t p=1;for(unsigned i=0;i<round+2;i++)p*=key;return p^key;}
static int valid_key(uint32_t key){for(unsigned i=0;i<32;i++)if(round_key(key,i)==0)return 0;return 1;}
static uint32_t f(uint32_t x,uint32_t key){for(int i=0;i<32;i++){x=(uint32_t)((uint32_t)((x^UINT32_C(0x55555555))*x)%key);x^=key;}return x;}
int64_t feistel_cipher_normalized(const int64_t *a,size_t n){if(!a||n!=3||a[0]<0||a[0]>1||a[1]<1||a[1]>UINT32_MAX)return -1;uint64_t b=(uint64_t)a[2];uint32_t l=(uint32_t)(b>>32),r=(uint32_t)b;uint32_t key=(uint32_t)a[1];if(!valid_key(key))return -1;if(a[0]==0){for(unsigned i=0;i<32;i++){uint32_t t=r^f(l,round_key(key,i));r=l;l=t;}}else{for(int i=31;i>=0;i--){uint32_t t=l^f(r,round_key(key,(unsigned)i));l=r;r=t;}}return (int64_t)(((uint64_t)l<<32)|r);}
