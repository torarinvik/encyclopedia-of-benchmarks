/* Port of the pinned Java ADTFraction record using a bounded packed ABI. */
#include <stddef.h>
#include <stdint.h>

static int32_t from_u32(uint32_t bits) {
    return bits <= INT32_MAX ? (int32_t)bits : (int32_t)((int64_t)bits - INT64_C(4294967296));
}
static int32_t wrap_add(int32_t a, int32_t b) { return from_u32((uint32_t)a + (uint32_t)b); }
static int32_t wrap_mul(int32_t a, int32_t b) { return from_u32((uint32_t)a * (uint32_t)b); }
static int64_t pack_fraction(int32_t n, int32_t d) {
    const uint64_t low = (uint64_t)(uint32_t)d;
    return (int64_t)n * INT64_C(4294967296) + (int64_t)low;
}

int64_t adtfraction(const int64_t *input, size_t length) {
    if (input == NULL || length != 5) return -1;
    for (size_t i = 0; i < 5; ++i) if (input[i] < -100000 || input[i] > 100000) return -1;
    if (input[0] < 0 || input[0] > 4) return -1;
    const int32_t op=(int32_t)input[0], n=(int32_t)input[1], d=(int32_t)input[2];
    const int32_t m=(int32_t)input[3], e=(int32_t)input[4];
    if (op == 0) {
        if (d == 0 || e == 0) return -1;
        int32_t out_n=wrap_add(wrap_mul(d,m),wrap_mul(n,e));
        int32_t out_d=wrap_mul(d,e);
        return out_d == 0 ? -1 : pack_fraction(out_n,out_d);
    }
    if (op == 1) return d == 0 ? -1 : pack_fraction(wrap_mul(n,m),d);
    if (op == 2) {
        if (d == 0 || e == 0) return -1;
        int32_t out_d=wrap_mul(d,e);
        return out_d == 0 ? -1 : pack_fraction(wrap_mul(n,m),out_d);
    }
    if (op == 3) return n == 0 ? -1 : pack_fraction(d,n);
    if (d == 0) return -1;
    float value=(float)n/(float)d;
    uint32_t bits;
    __builtin_memcpy(&bits,&value,sizeof(bits));
    return (int64_t)bits;
}
