#include <stddef.h>
#include <stdint.h>
int64_t elementary(const int64_t *v, size_t n, uint8_t *out, size_t cap) {
    if (!v || n < 2 || n > 129 || v[0] < 1 || v[0] > 128 || n != (size_t)v[0] + 1) return -1;
    size_t count = (size_t)v[0];
    if (v[1] != 0) return -1;
    for (size_t i = 1; i < n; ++i) if (v[i] != 0 && v[i] != 1) return -1;
    if (cap < count || !out) return -2;
    for (size_t i = 0; i < count; ++i) {
        int left = i > 0 ? (int)v[i] : 0;
        int center = (int)v[i + 1];
        int right = i + 1 < count ? (int)v[i + 2] : 0;
        unsigned pattern = (unsigned)(left * 4 + center * 2 + right);
        out[i] = (uint8_t)((30u >> pattern) & 1u);
    }
    return (int64_t)count;
}
