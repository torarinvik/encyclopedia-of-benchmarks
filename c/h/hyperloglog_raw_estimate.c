#include <stddef.h>
#include <stdint.h>

static uint64_t hll_gcd(uint64_t a, uint64_t b) {
    while (b != 0) { uint64_t r = a % b; a = b; b = r; }
    return a;
}

int64_t hyperloglog_raw_estimate(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 130) return -1;
    int64_t raw = input[0];
    if (raw < 0 || raw > 128 || length != (size_t)raw + 1) return -1;
    uint8_t registers[16] = {0};
    for (size_t i = 0; i < (size_t)raw; ++i) {
        int64_t value = input[i+1];
        if (value < 0 || (uint64_t)value > UINT32_MAX) return -1;
        uint32_t hash = (uint32_t)value;
        unsigned bucket = hash >> 28;
        uint32_t suffix = hash & UINT32_C(0x0fffffff);
        unsigned rank = 1;
        for (uint32_t mask = UINT32_C(1) << 27; mask && !(suffix & mask); mask >>= 1) ++rank;
        if (rank > registers[bucket]) registers[bucket] = (uint8_t)rank;
    }
    uint64_t sum = 0;
    for (size_t i = 0; i < 16; ++i) sum += UINT64_C(1) << (29-registers[i]);
    uint64_t num = UINT64_C(673)*256*(UINT64_C(1)<<29), den = 1000*sum;
    uint64_t factor = hll_gcd(num,den);
    num /= factor; den /= factor;
    if (output == NULL || capacity < 144) return -2;
    uint64_t words[18] = {0};
    words[0] = num; words[1] = den;
    for (size_t i = 0; i < 16; ++i) words[i+2] = registers[i];
    uint8_t staged[144];
    for (size_t i = 0; i < 18; ++i)
        for (size_t byte = 0; byte < 8; ++byte)
            staged[8*i+byte] = (uint8_t)(words[i] >> (8*byte));
    for (size_t i = 0; i < 144; ++i) output[i] = staged[i];
    return 144;
}
