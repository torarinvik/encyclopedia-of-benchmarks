#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255); bits >>= 8; }
}

int64_t three_dimensional_moment_curve(const int64_t *values, size_t length,
                                       uint8_t *output, size_t capacity) {
    if (values == NULL || length != 1 || values[0] < 0 || values[0] > 64) return -1;
    const size_t n = (size_t)values[0], bytes = 8 * (1 + 3 * n);
    if (output == NULL || capacity < bytes) return -2;
    uint8_t staged[1544];
    put_i64(staged, 0, (int64_t)n);
    for (size_t i = 1; i <= n; ++i) {
        const int64_t x = (int64_t)i;
        put_i64(staged, 8 * (1 + 3 * (i - 1)), x);
        put_i64(staged, 8 * (2 + 3 * (i - 1)), x * x);
        put_i64(staged, 8 * (3 + 3 * (i - 1)), x * x * x);
    }
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
