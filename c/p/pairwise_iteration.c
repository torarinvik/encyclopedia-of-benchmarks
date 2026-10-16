#include <stddef.h>
#include <stdint.h>

int64_t pairwise_iteration(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 1 || n > 129 || v[0] < 0 || v[0] > 128 || n != (size_t)v[0] + 1) return -1;
    size_t count = (size_t)v[0], bytes = count > 0 ? (count - 1) * 16 : 0;
    for (size_t i = 0; i < count; ++i) if (v[i + 1] < -1000000 || v[i + 1] > 1000000) return -1;
    if (bytes > cap || (bytes && !out)) return -2;
    size_t k = 0;
    for (size_t i = 0; i + 1 < count; ++i) for (size_t j = i; j <= i + 1; ++j) {
        uint64_t x = (uint64_t)v[j + 1];
        for (size_t b = 0; b < 8; ++b) out[k++] = (uint8_t)(x >> (8 * b));
    }
    return (int64_t)bytes;
}
