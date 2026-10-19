#include <stddef.h>
#include <stdint.h>

#define MAX_TEXT 40
#define MAX_INPUT (2 + MAX_TEXT)
#define MAX_OUTPUT 40
static const unsigned char IP[64]={58,50,42,34,26,18,10,2,60,52,44,36,28,20,12,4,62,54,46,38,30,22,14,6,64,56,48,40,32,24,16,8,57,49,41,33,25,17,9,1,59,51,43,35,27,19,11,3,61,53,45,37,29,21,13,5,63,55,47,39,31,23,15,7};
static const unsigned char IP_INV[64]={40,8,48,16,56,24,64,32,39,7,47,15,55,23,63,31,38,6,46,14,54,22,62,30,37,5,45,13,53,21,61,29,36,4,44,12,52,20,60,28,35,3,43,11,51,19,59,27,34,2,42,10,50,18,58,26,33,1,41,9,49,17,57,25};
static const unsigned char E[48]={32,1,2,3,4,5,4,5,6,7,8,9,8,9,10,11,12,13,12,13,14,15,16,17,16,17,18,19,20,21,20,21,22,23,24,25,24,25,26,27,28,29,28,29,30,31,32,1};
static const unsigned char P[32]={16,7,20,21,29,12,28,17,1,15,23,26,5,18,31,10,2,8,24,14,32,27,3,9,19,13,30,6,22,11,4,25};
static const unsigned char PC1[56]={57,49,41,33,25,17,9,1,58,50,42,34,26,18,10,2,59,51,43,35,27,19,11,3,60,52,44,36,63,55,47,39,31,23,15,7,62,54,46,38,30,22,14,6,61,53,45,37,29,21,13,5,28,20,12,4};
static const unsigned char PC2[48]={14,17,11,24,1,5,3,28,15,6,21,10,23,19,12,4,26,8,16,7,27,20,13,2,41,52,31,37,47,55,30,40,51,45,33,48,44,49,39,56,34,53,46,42,50,36,29,32};
static const unsigned char SHIFTS[16]={1,1,2,2,2,2,2,2,1,2,2,2,2,2,2,1};
static const unsigned char SBOX[8][4][16]={
{{14,4,13,1,2,15,11,8,3,10,6,12,5,9,0,7},{0,15,7,4,14,2,13,1,10,6,12,11,9,5,3,8},{4,1,14,8,13,6,2,11,15,12,9,7,3,10,5,0},{15,12,8,2,4,9,1,7,5,11,3,14,10,0,6,13}},
{{15,1,8,14,6,11,3,4,9,7,2,13,12,0,5,10},{3,13,4,7,15,2,8,14,12,0,1,10,6,9,11,5},{0,14,7,11,10,4,13,1,5,8,12,6,9,3,2,15},{13,8,10,1,3,15,4,2,11,6,7,12,0,5,14,9}},
{{10,0,9,14,6,3,15,5,1,13,12,7,11,4,2,8},{13,7,0,9,3,4,6,10,2,8,5,14,12,11,15,1},{13,6,4,9,8,15,3,0,11,1,2,12,5,10,14,7},{1,10,13,0,6,9,8,7,4,15,14,3,11,5,2,12}},
{{7,13,14,3,0,6,9,10,1,2,8,5,11,12,4,15},{13,8,11,5,6,15,0,3,4,7,2,12,1,10,14,9},{10,6,9,0,12,11,7,13,15,1,3,14,5,2,8,4},{3,15,0,6,10,1,13,8,9,4,5,11,12,7,2,14}},
{{2,12,4,1,7,10,11,6,8,5,3,15,13,0,14,9},{14,11,2,12,4,7,13,1,5,0,15,10,3,9,8,6},{4,2,1,11,10,13,7,8,15,9,12,5,6,3,0,14},{11,8,12,7,1,14,2,13,6,15,0,9,10,4,5,3}},
{{12,1,10,15,9,2,6,8,0,13,3,4,14,7,5,11},{10,15,4,2,7,12,9,5,6,1,13,14,0,11,3,8},{9,14,15,5,2,8,12,3,7,0,4,10,1,13,11,6},{4,3,2,12,9,5,15,10,11,14,1,7,6,0,8,13}},
{{4,11,2,14,15,0,8,13,3,12,9,7,5,10,6,1},{13,0,11,7,4,9,1,10,14,3,5,12,2,15,8,6},{1,4,11,13,12,3,7,14,10,15,6,8,0,5,9,2},{6,11,13,8,1,4,10,7,9,5,0,15,14,2,3,12}},
{{13,2,8,4,6,15,11,1,10,9,3,14,5,0,12,7},{1,15,13,8,10,3,7,4,12,5,6,11,0,14,9,2},{7,11,4,1,9,12,14,2,0,6,10,13,15,3,5,8},{2,1,14,7,4,10,8,13,15,12,9,0,3,5,6,11}}};

static uint64_t permute(uint64_t v,const unsigned char *table,size_t n,unsigned width){uint64_t r=0;for(size_t i=0;i<n;i++)r=(r<<1)|((v>>(width-table[i]))&1u);return r;}
static void make_keys(uint64_t key,uint64_t keys[16]){uint64_t t=permute(key,PC1,56,64),mask=(UINT64_C(1)<<28)-1;uint32_t c=(uint32_t)(t>>28),d=(uint32_t)(t&mask);for(int i=0;i<16;i++){unsigned s=SHIFTS[i];c=((c<<s)|(c>>(28-s)))&(uint32_t)mask;d=((d<<s)|(d>>(28-s)))&(uint32_t)mask;keys[i]=permute(((uint64_t)c<<28)|d,PC2,48,56);}}
static uint32_t feistel_salted(uint32_t r,uint64_t key,uint16_t salt){unsigned char ex[48];for(unsigned i=0;i<48;i++)ex[i]=E[i];for(unsigned i=0;i<12;i++)if((salt>>i)&1u){unsigned char t=ex[i];ex[i]=ex[i+24];ex[i+24]=t;}uint64_t x=permute(r,ex,48,32)^key;uint32_t s=0;for(unsigned i=0;i<8;i++){unsigned six=(unsigned)((x>>(42-6*i))&63),row=((six&32)>>4)|(six&1),col=(six>>1)&15;s=(s<<4)|SBOX[i][row][col];}return (uint32_t)permute(s,P,32,32);}
static uint64_t encrypt_block_salted(uint64_t b,const uint64_t keys[16],uint16_t salt){uint64_t s=permute(b,IP,64,64);uint32_t l=(uint32_t)(s>>32),r=(uint32_t)s;for(int i=0;i<16;i++){uint32_t next=l^feistel_salted(r,keys[i],salt);l=r;r=next;}return permute(((uint64_t)r<<32)|l,IP_INV,64,64);}
static int crypt_value(unsigned char c){static const char alphabet[]="./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";if(c=='@')return 11;for(int i=0;i<64;i++)if((unsigned char)alphabet[i]==c)return i;return -1;}
static int password_char(unsigned char c){static const char allowed[]=" !\"$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{|}";for(size_t i=0;i<sizeof(allowed)-1;i++)if((unsigned char)allowed[i]==c)return 1;return 0;}
static void encode_trip(uint64_t block,uint8_t out[13]){static const char alphabet[]="./0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";/* DES_fcrypt serializes the two DES words little-endian before taking successive high bits. */uint8_t b[8];for(unsigned i=0;i<8;i++)b[i]=(uint8_t)(block>>(8*(i%4)+(i<4?32:0)));for(unsigned k=0;k<11;k++){unsigned v=0;for(unsigned j=0;j<6;j++){unsigned bit=k*6+j;v<<=1;if(bit<64)v|=(b[bit/8]>>(7-(bit%8)))&1u;}out[k]=(uint8_t)alphabet[v];}}
int64_t tripforce_tripcode(const int64_t *input,size_t length,uint8_t *output,size_t capacity){if(!input||length!=8)return -1;unsigned char p[8];for(size_t i=0;i<8;i++){if(input[i]<0||input[i]>127||!password_char((unsigned char)input[i]))return -1;p[i]=(unsigned char)input[i];}unsigned char s0=p[1],s1=p[2];for(unsigned i=0;i<2;i++){unsigned char *c=i?&s1:&s0;if(*c<'.'||*c>'z')*c='.';if(*c>=':'&&*c<='@')*c=(unsigned char)(*c+6);else if(*c>='['&&*c<='`')*c=(unsigned char)(*c+6);}int a=crypt_value(s0),b=crypt_value(s1);if(a<0||b<0)return -1;if(!output||capacity<10)return -2;uint16_t salt=(uint16_t)(a|(b<<6));unsigned char key[8];for(unsigned i=0;i<8;i++)key[i]=(unsigned char)(p[i]<<1);uint64_t k=0;for(unsigned i=0;i<8;i++)k=(k<<8)|key[i];uint64_t keys[16];make_keys(k,keys);uint64_t block=0;for(unsigned i=0;i<25;i++)block=encrypt_block_salted(block,keys,salt);uint8_t hash[13];encode_trip(block,hash);for(unsigned i=0;i<10;i++)output[i]=hash[i+1];return 10;}
