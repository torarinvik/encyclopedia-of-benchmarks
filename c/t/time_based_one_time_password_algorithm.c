#include <stddef.h>
#include <stdint.h>

enum { MAX_KEY = 64, MAX_WORDS = 67, OUT_BYTES = 6 };

static uint32_t rol(uint32_t x, unsigned n) { return (x << n) | (x >> (32u - n)); }

static void compress_sha1(uint32_t h[5], const uint8_t block[64]) {
    uint32_t w[80];
    for (size_t i = 0; i < 16; ++i) {
        size_t j = i * 4;
        w[i] = ((uint32_t)block[j] << 24) | ((uint32_t)block[j+1] << 16) |
               ((uint32_t)block[j+2] << 8) | (uint32_t)block[j+3];
    }
    for (size_t i = 16; i < 80; ++i) w[i] = rol(w[i-3] ^ w[i-8] ^ w[i-14] ^ w[i-16], 1);
    uint32_t a=h[0], b=h[1], c=h[2], d=h[3], e=h[4];
    for (size_t i = 0; i < 80; ++i) {
        uint32_t f, k;
        if (i < 20) { f=(b&c)|((~b)&d); k=0x5a827999u; }
        else if (i < 40) { f=b^c^d; k=0x6ed9eba1u; }
        else if (i < 60) { f=(b&c)|(b&d)|(c&d); k=0x8f1bbcdcu; }
        else { f=b^c^d; k=0xca62c1d6u; }
        uint32_t t=rol(a,5)+f+e+k+w[i];
        e=d; d=c; c=rol(b,30); b=a; a=t;
    }
    h[0]+=a; h[1]+=b; h[2]+=c; h[3]+=d; h[4]+=e;
}

static void initial_state(uint32_t h[5]) {
    h[0]=0x67452301u; h[1]=0xefcdab89u; h[2]=0x98badcfeu;
    h[3]=0x10325476u; h[4]=0xc3d2e1f0u;
}

static void store_digest(const uint32_t h[5], uint8_t out[20]) {
    for (size_t i=0;i<5;++i) {
        out[4*i]=(uint8_t)(h[i]>>24); out[4*i+1]=(uint8_t)(h[i]>>16);
        out[4*i+2]=(uint8_t)(h[i]>>8); out[4*i+3]=(uint8_t)h[i];
    }
}

static void hmac_sha1_totp(const int64_t *input, size_t key_len, uint8_t out[6]) {
    uint8_t normalized[64]={0}, block[64]={0}, inner[20];
    uint32_t h[5];
    for (size_t i=0;i<key_len;++i) normalized[i]=(uint8_t)input[1+i];
    for (size_t i=0;i<64;++i) block[i]=(uint8_t)(normalized[i]^0x36u);
    initial_state(h); compress_sha1(h,block);
    for (size_t i=0;i<64;++i) block[i]=0;
    uint64_t counter=(uint64_t)input[key_len+1]/30u;
    for (size_t i=0;i<8;++i) block[i]=(uint8_t)(counter>>(56-8*i));
    block[8]=0x80u; block[56]=0x00u; block[57]=0x00u; block[58]=0x00u; block[59]=0x00u;
    block[60]=0x00u; block[61]=0x00u; block[62]=0x02u; block[63]=0x40u;
    compress_sha1(h,block); store_digest(h,inner);
    for (size_t i=0;i<64;++i) block[i]=(uint8_t)(normalized[i]^0x5cu);
    initial_state(h); compress_sha1(h,block);
    for (size_t i=0;i<64;++i) block[i]=0;
    for (size_t i=0;i<20;++i) block[i]=inner[i];
    block[20]=0x80u; block[62]=0x02u; block[63]=0xa0u;
    compress_sha1(h,block);
    store_digest(h,inner);
    unsigned offset=inner[19]&15u;
    uint32_t binary=((uint32_t)inner[offset]<<24)|((uint32_t)inner[offset+1]<<16)|
                    ((uint32_t)inner[offset+2]<<8)|inner[offset+3];
    binary &= 0x7fffffffu;
    uint32_t value=binary%1000000u;
    for (int i=5;i>=0;--i) { out[i]=(uint8_t)('0'+value%10u); value/=10u; }
}

int64_t time_based_one_time_password_algorithm(const int64_t *input, size_t length,
                                                uint8_t *output, size_t capacity) {
    if (input==NULL || length<3 || length>MAX_WORDS) return -1;
    int64_t key_word=input[0];
    if (key_word<16 || key_word>MAX_KEY || length!=(size_t)key_word+2) return -1;
    size_t key_len=(size_t)key_word;
    for (size_t i=0;i<key_len;++i) if (input[i+1]<0 || input[i+1]>255) return -1;
    if (input[key_len+1]<0) return -1;
    uint8_t staged[OUT_BYTES];
    hmac_sha1_totp(input,key_len,staged);
    if (output==NULL || capacity<OUT_BYTES) return -2;
    for (size_t i=0;i<OUT_BYTES;++i) output[i]=staged[i];
    return OUT_BYTES;
}
