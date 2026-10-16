#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 4096
#define MAX_PADDED 4160

static const uint32_t K[64] = {
    0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
    0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
    0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
    0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
    0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
    0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
    0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
    0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
};
static uint32_t rotr(uint32_t x, unsigned n) { return (x >> n) | (x << (32 - n)); }

int64_t sha256(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (length > MAX_INPUT || (length > 0 && input == NULL)) return -1;
    for (size_t i=0;i<length;++i) if(input[i]<0||input[i]>255)return -1;
    uint8_t padded[MAX_PADDED]={0};
    for(size_t i=0;i<length;++i)padded[i]=(uint8_t)input[i];
    padded[length]=0x80;
    const size_t blocks=(length+9+63)/64, padded_length=blocks*64;
    const uint64_t bit_length=(uint64_t)length*8;
    for(size_t i=0;i<8;++i)padded[padded_length-1-i]=(uint8_t)(bit_length>>(8*i));
    uint32_t h[8]={0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19};
    for(size_t block=0;block<blocks;++block){
        uint32_t w[64];
        for(size_t i=0;i<16;++i){size_t p=block*64+i*4;w[i]=((uint32_t)padded[p]<<24)|((uint32_t)padded[p+1]<<16)|((uint32_t)padded[p+2]<<8)|padded[p+3];}
        for(size_t i=16;i<64;++i){uint32_t s0=rotr(w[i-15],7)^rotr(w[i-15],18)^(w[i-15]>>3);uint32_t s1=rotr(w[i-2],17)^rotr(w[i-2],19)^(w[i-2]>>10);w[i]=s1+w[i-7]+s0+w[i-16];}
        uint32_t a=h[0],b=h[1],c=h[2],d=h[3],e=h[4],f=h[5],g=h[6],hh=h[7];
        for(size_t i=0;i<64;++i){uint32_t s1=rotr(e,6)^rotr(e,11)^rotr(e,25);uint32_t ch=(e&f)^(~e&g);uint32_t t1=hh+s1+ch+K[i]+w[i];uint32_t s0=rotr(a,2)^rotr(a,13)^rotr(a,22);uint32_t maj=(a&b)^(a&c)^(b&c);uint32_t t2=s0+maj;hh=g;g=f;f=e;e=d+t1;d=c;c=b;b=a;a=t1+t2;}
        h[0]+=a;h[1]+=b;h[2]+=c;h[3]+=d;h[4]+=e;h[5]+=f;h[6]+=g;h[7]+=hh;
    }
    if(output==NULL||capacity<32)return -2;
    for(size_t i=0;i<8;++i)for(size_t byte=0;byte<4;++byte)output[i*4+byte]=(uint8_t)(h[i]>>(24-8*byte));
    return 32;
}

static const char HEX[]="0123456789abcdef";
int64_t merkle_tree(const int64_t* input,size_t length,uint8_t* output,size_t capacity){
 if(input==NULL||length<1||length>1041)return -1;int64_t count64=input[0];if(count64<1||count64>16)return -1;size_t count=(size_t)count64,pos=1;uint8_t level[16][64],raw[32];
 for(size_t leaf=0;leaf<count;leaf++){if(pos>=length)return -1;int64_t n64=input[pos++];if(n64<0||n64>64||pos+(size_t)n64>length)return -1;for(size_t j=0;j<(size_t)n64;j++)if(input[pos+j]<0||input[pos+j]>127)return -1;if(sha256(input+pos,(size_t)n64,raw,32)!=32)return -1;for(size_t j=0;j<32;j++){level[leaf][2*j]=(uint8_t)HEX[raw[j]>>4];level[leaf][2*j+1]=(uint8_t)HEX[raw[j]&15];}pos+=(size_t)n64;}
 if(pos!=length)return -1;while(count>1){size_t next=0;for(size_t i=0;i<count;i+=2){size_t r=i+1<count?i+1:i;int64_t data[128];for(size_t j=0;j<64;j++){data[j]=level[i][j];data[64+j]=level[r][j];}if(sha256(data,128,raw,32)!=32)return -1;for(size_t j=0;j<32;j++){level[next][2*j]=(uint8_t)HEX[raw[j]>>4];level[next][2*j+1]=(uint8_t)HEX[raw[j]&15];}next++;}count=next;}
 if(output==NULL||capacity<64)return -2;for(size_t j=0;j<64;j++)output[j]=level[0][j];return 64;
}
