#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 8
#define MAX_INPUT (1 + 13 * MAX_OPS)
#define MAX_OUTPUT (12 * MAX_OPS)
#define MIN_EXP (-32767)

typedef struct { uint8_t type, sign; int16_t exp; uint64_t mant; } IFPF;

static void sticky_right(IFPF *v, unsigned count) {
    while (count-- != 0) {
        uint64_t lost = v->mant & 1u;
        v->mant >>= 1;
        if (lost) v->mant |= 1u;
    }
}
static void round_result(IFPF *v) {
    if (v->type == 2) v->mant &= ~UINT64_C(7);
}
static void normalize(IFPF *v) {
    while ((v->mant >> 63) == 0) { v->mant <<= 1; --v->exp; }
}
static IFPF add_sub(IFPF x, IFPF y, unsigned operation) {
    IFPF z = {2, x.sign, x.exp, 0};
    int difference = (int)x.exp - (int)y.exp;
    if (difference > 0) sticky_right(&y, (unsigned)difference);
    else if (difference < 0) { sticky_right(&x, (unsigned)-difference); z.sign = y.sign ^ operation; z.exp = y.exp; }
    if (x.sign ^ y.sign ^ operation) {
        z.mant = x.mant - y.mant;
        if (x.mant < y.mant) { z.sign = y.sign ^ operation; z.mant = y.mant - x.mant; }
        if (z.mant == 0) { z.type = 0; z.sign = 0; z.exp = MIN_EXP; }
        else normalize(&z);
    } else {
        z.mant = x.mant + y.mant;
        if (z.mant < x.mant) { ++z.exp; z.mant = (z.mant >> 1) | UINT64_C(0x8000000000000000); }
    }
    round_result(&z);
    return z;
}
static IFPF multiply(IFPF x, IFPF y) {
    IFPF z = {2, (uint8_t)(x.sign ^ y.sign), (int16_t)(x.exp + y.exp), 0};
    uint64_t high = 0, low = 0, multiplier = y.mant;
    for (unsigned i=0; i<64; ++i) {
        uint64_t carry = 0;
        if (multiplier & 1u) { uint64_t old=high; high += x.mant; carry=(high<old); }
        multiplier >>= 1;
        uint64_t outgoing = high & 1u;
        high = (high >> 1) | (carry << 63);
        low = (low >> 1) | (outgoing << 63);
    }
    while ((high >> 63) == 0) {
        uint64_t carry = low >> 63;
        low <<= 1;
        high = (high << 1) | carry;
        --z.exp;
    }
    if (low == 0) high |= 1u;
    z.mant = high;
    round_result(&z);
    return z;
}
static IFPF divide_emulated(IFPF x, IFPF y) {
    IFPF z = {2, (uint8_t)(x.sign ^ y.sign), (int16_t)(x.exp - y.exp + 128), 0};
    uint64_t dividend=x.mant, remainder=0;
    while ((z.mant >> 63) == 0) {
        uint64_t carry=dividend >> 63;
        dividend <<= 1;
        uint64_t remainder_overflow=remainder >> 63;
        remainder=(remainder << 1) | carry;
        uint64_t quotient_bit=0;
        if (remainder_overflow != 0 || remainder >= y.mant) { remainder -= y.mant; quotient_bit=1; }
        z.mant=(z.mant << 1) | quotient_bit;
        --z.exp;
    }
    round_result(&z);
    return z;
}

int64_t nbench_emulated_float_arithmetic(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 14 || length > MAX_INPUT + 1) return -1;
    int64_t count=input[0];
    if (count < 1 || count > MAX_OPS || length != 1 + 13*(size_t)count) return -1;
    IFPF result[MAX_OPS];
    for (size_t i=0; i<(size_t)count; ++i) {
        size_t p=1+13*i;
        int64_t op=input[p], sx=input[p+1], ex=input[p+2], sy=input[p+7], ey=input[p+8];
        if (op<0||op>3||sx<0||sx>1||sy<0||sy>1||ex< -8||ex>8||ey< -8||ey>8) return -1;
        uint64_t mx=0,my=0;
        for (size_t j=0;j<4;++j) { int64_t w=input[p+3+j],v=input[p+9+j]; if(w<0||w>65535||v<0||v>65535)return -1; mx=(mx<<16)|(uint16_t)w; my=(my<<16)|(uint16_t)v; }
        if ((mx>>63)==0 || (my>>63)==0) return -1;
        IFPF x={2,(uint8_t)sx,(int16_t)ex,mx}, y={2,(uint8_t)sy,(int16_t)ey,my};
        if(op==0)result[i]=add_sub(x,y,0);
        else if(op==1)result[i]=add_sub(x,y,1);
        else if(op==2)result[i]=multiply(x,y);
        else result[i]=divide_emulated(x,y);
        if(result[i].type==2&&(result[i].exp < -32 || result[i].exp > 32 || (result[i].mant>>63)==0))return -1;
    }
    size_t bytes=(size_t)count*12;
    if(!output||capacity<bytes)return -2;
    for(size_t i=0;i<(size_t)count;++i){
        IFPF v=result[i];size_t p=i*12;output[p]=v.type;output[p+1]=v.sign;
        uint16_t exp=(uint16_t)v.exp;output[p+2]=(uint8_t)exp;output[p+3]=(uint8_t)(exp>>8);
        for(size_t j=0;j<4;++j){uint16_t word=(uint16_t)(v.mant>>(48-16*j));output[p+4+2*j]=(uint8_t)word;output[p+5+2*j]=(uint8_t)(word>>8);}
    }
    return (int64_t)bytes;
}
