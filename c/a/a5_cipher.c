#include <stddef.h>
#include <stdint.h>

typedef struct { uint32_t r1, r2, r3; } a5_state;

static uint32_t parity(uint32_t x) { x ^= x >> 16; x ^= x >> 8; x ^= x >> 4; x ^= x >> 2; x ^= x >> 1; return x & 1u; }
static uint32_t fb1(const a5_state *s) { return parity(s->r1 & ((1u<<13)|(1u<<16)|(1u<<17)|(1u<<18))); }
static uint32_t fb2(const a5_state *s) { return parity(s->r2 & ((1u<<20)|(1u<<21))); }
static uint32_t fb3(const a5_state *s) { return parity(s->r3 & ((1u<<7)|(1u<<20)|(1u<<21)|(1u<<22))); }
static uint32_t push(uint32_t r, unsigned len, uint32_t bit) { return ((r << 1) | bit) & ((1u << len) - 1u); }
static void init(a5_state *s, uint64_t key, uint32_t frame) {
    s->r1=s->r2=s->r3=0;
    for (int i=63;i>=0;--i) { s->r1=push(s->r1,19,((key>>i)&1u)^fb1(s)); s->r2=push(s->r2,22,((key>>i)&1u)^fb2(s)); s->r3=push(s->r3,23,((key>>i)&1u)^fb3(s)); }
    for (int i=21;i>=0;--i) { s->r1=push(s->r1,19,((frame>>i)&1u)^fb1(s)); s->r2=push(s->r2,22,((frame>>i)&1u)^fb2(s)); s->r3=push(s->r3,23,((frame>>i)&1u)^fb3(s)); }
}
static uint32_t tick(a5_state *s) {
    uint32_t c1=(s->r1>>8)&1u, c2=(s->r2>>10)&1u, c3=(s->r3>>10)&1u;
    uint32_t majority=(c1+c2+c3)>=2u;
    uint32_t out=((s->r1>>18)^(s->r2>>21)^(s->r3>>22))&1u;
    if (c1==majority) s->r1=push(s->r1,19,fb1(s));
    if (c2==majority) s->r2=push(s->r2,22,fb2(s));
    if (c3==majority) s->r3=push(s->r3,23,fb3(s));
    return out;
}
static uint32_t next_frame(uint32_t f) { for (int i=21;i>=0;--i) { uint32_t m=1u<<i; if ((f&m)==0) return f|m; f&=~m; } return f; }

int64_t a5_cipher(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input==NULL || length<3 || input[2]<1 || input[2]>4) return -1;
    size_t blocks=(size_t)input[2];
    if (length!=3+4*blocks) return -1;
    size_t bytes=32*blocks;
    if (capacity<bytes || output==NULL) return -2;
    uint64_t key=(uint64_t)input[0]; uint32_t frame=(uint32_t)((uint64_t)input[1]&0x3fffffu);
    for (size_t block=0;block<blocks;++block) {
        a5_state s; init(&s,key,frame);
        for (int i=0;i<100;++i) (void)tick(&s);
        uint8_t *dst=output+32*block;
        for (int i=0;i<32;++i) dst[i]=0;
        for (int bit=0;bit<228;++bit) {
            uint64_t plain=(uint64_t)input[3+4*block+(size_t)(bit/64)];
            uint32_t value=(uint32_t)((plain>>(bit%64))&1u)^tick(&s);
            dst[bit/8]|=(uint8_t)(value<<(bit%8));
        }
        for (int bit=228;bit<256;++bit) {
            uint64_t plain=(uint64_t)input[3+4*block+(size_t)(bit/64)];
            dst[bit/8]|=(uint8_t)(((plain>>(bit%64))&1u)<<(bit%8));
        }
        frame=next_frame(frame);
    }
    return (int64_t)bytes;
}
