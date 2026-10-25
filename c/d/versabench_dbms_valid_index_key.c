#include <stddef.h>
#include <stdint.h>

static int binary32_ge(uint32_t a, uint32_t b) {
    const uint32_t exp_a = (a >> 23) & 0xffu, frac_a = a & 0x7fffffu;
    const uint32_t exp_b = (b >> 23) & 0xffu, frac_b = b & 0x7fffffu;
    if ((exp_a == 0xffu && frac_a != 0) || (exp_b == 0xffu && frac_b != 0)) return 0;
    const uint32_t mag_a = a & 0x7fffffffu, mag_b = b & 0x7fffffffu;
    if (mag_a == 0 && mag_b == 0) return 1;
    const int neg_a = (a >> 31) != 0, neg_b = (b >> 31) != 0;
    if (neg_a != neg_b) return !neg_a;
    return neg_a ? mag_a <= mag_b : mag_a >= mag_b;
}

int64_t versabench_dbms_valid_index_key(const int64_t *values, size_t length) {
    if (values == NULL || length < 1 || length > 9 || length != 8) return -1;
    uint32_t bits[8];
    for (size_t i = 0; i < 8; ++i) {
        if (values[i] < 0 || (uint64_t)values[i] > UINT32_MAX) return -1;
        bits[i] = (uint32_t)values[i];
    }
    for (size_t d = 0; d < 4; ++d) if (binary32_ge(bits[d], bits[4+d])) return 0;
    return 1;
}
