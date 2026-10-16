#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT 8192
#define MAX_PADDED 8256

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


static int64_t merkle_signature_scheme_verify(const int64_t *input, size_t height,
        size_t w, size_t msg_len, size_t leaf_index, size_t sig_pos,
        size_t pk_pos, size_t auth_pos, size_t root_pos, size_t l) {
    uint8_t digest[32], current[32];
    if (sha256(input + 3, msg_len, digest, sizeof(digest)) != 32) return 0;
    uint8_t digits[133];
    size_t log_w = w == 4 ? 2 : (w == 16 ? 4 : 8);
    size_t len1 = w == 4 ? 128 : (w == 16 ? 64 : 32);
    size_t len2 = l - len1, digit = 0;
    int checksum = 0, mask = (int)w - 1;
    for (size_t i = 0; i < 32; ++i) {
        for (size_t part = 0; part < 8 / log_w; ++part) {
            unsigned shift = (unsigned)(8 - log_w * (part + 1));
            digits[digit] = (uint8_t)((digest[i] >> shift) & mask);
            checksum += mask - digits[digit++];
        }
    }
    for (size_t i = 0; i < len2; ++i) {
        digits[len1 + len2 - 1 - i] = (uint8_t)(checksum & mask);
        checksum >>= log_w;
    }
    int64_t chain[32];
    for (size_t i = 0; i < l; ++i) {
        for (size_t j = 0; j < 32; ++j) chain[j] = input[sig_pos + 32 * i + j];
        size_t steps = w - 1 - digits[i];
        for (size_t step = 0; step < steps; ++step) {
            if (sha256(chain, 32, current, sizeof(current)) != 32) return 0;
            for (size_t j = 0; j < 32; ++j) chain[j] = current[j];
        }
        for (size_t j = 0; j < 32; ++j)
            if ((uint8_t)chain[j] != (uint8_t)input[pk_pos + 32 * i + j]) return 0;
    }
    if (sha256(input + pk_pos, 32 * l, digest, sizeof(digest)) != 32) return 0;
    int64_t pair[64];
    size_t index = leaf_index;
    for (size_t level = 0; level < height; ++level) {
        for (size_t j = 0; j < 32; ++j) {
            int64_t left = digest[j];
            int64_t right = input[auth_pos + 32 * level + j];
            pair[j] = index % 2 == 0 ? left : right;
            pair[32 + j] = index % 2 == 0 ? right : left;
        }
        if (sha256(pair, 64, digest, sizeof(digest)) != 32) return 0;
        index >>= 1;
    }
    for (size_t j = 0; j < 32; ++j)
        if (digest[j] != (uint8_t)input[root_pos + j]) return 0;
    return 1;
}

int64_t merkle_signature_scheme(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > 8932) return -1;
    int64_t h64=input[0], w64=input[1], m64=input[2];
    if (h64<2||h64>10||(w64!=4&&w64!=16&&w64!=256)||m64<0||m64>64) return -1;
    size_t height=(size_t)h64,w=(size_t)w64,msg_len=(size_t)m64;
    size_t l=w==4?133:(w==16?67:34), index_pos=3+msg_len;
    size_t expected=4+msg_len+64*l+32*height+32;
    if(length!=expected)return -1;
    for(size_t i=0;i<msg_len;i++)if(input[3+i]<0||input[3+i]>127)return -1;
    int64_t index64=input[index_pos];if(index64<0||(uint64_t)index64>=(UINT64_C(1)<<height))return -1;
    size_t sig_pos=index_pos+1,pk_pos=sig_pos+32*l,auth_pos=pk_pos+32*l,root_pos=auth_pos+32*height;
    for(size_t i=sig_pos;i<length;i++)if(input[i]<0||input[i]>255)return -1;
    if(output==NULL||capacity<8)return -2;
    int64_t valid=merkle_signature_scheme_verify(input,height,w,msg_len,(size_t)index64,sig_pos,pk_pos,auth_pos,root_pos,l);
    for(size_t i=0;i<8;i++)output[i]=0;output[0]=(uint8_t)valid;return 8;
}
