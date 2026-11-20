/* Uncompiled indexed Calkin–Wilf fraction draft. */
#include <stddef.h>
#include <stdint.h>

int64_t calkin_wilf_index(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length != 1 || input[0] < 1 || input[0] >= (INT64_C(1) << 62)) return -1;
    if (!output || capacity < 16) return -2;
    uint64_t index = (uint64_t)input[0], high = 1;
    while (high <= index / 2) high *= 2;
    uint64_t numerator = 1, denominator = 1;
    for (high /= 2; high != 0; high /= 2) {
        if (index & high) numerator += denominator;
        else denominator += numerator;
    }
    for (size_t i = 0; i < 8; ++i) {
        output[i] = (uint8_t)(numerator >> (8*i));
        output[i+8] = (uint8_t)(denominator >> (8*i));
    }
    return 16;
}
