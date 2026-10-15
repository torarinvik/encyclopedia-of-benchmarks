/* Emit a bounded geometric term sequence as little-endian binary64 values. */
#include <stddef.h>
#include <stdint.h>
#include <string.h>

static void put_f64_le(uint8_t *out, size_t offset, double value) {
    uint64_t bits; memcpy(&bits, &value, sizeof(bits));
    for (size_t byte = 0; byte < 8; ++byte) out[offset + byte] = (uint8_t)(bits >> (8 * byte));
}
int64_t geometric_series(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length != 3 || input[0] < 0 || input[0] > 16 ||
        input[1] < 1 || input[1] > 8 || input[2] < 1 || input[2] > 4) return -1;
    size_t n = (size_t)input[0];
    if (capacity < n * 8 || (n > 0 && output == NULL)) return -2;
    double term = (double)input[1], ratio = (double)input[2];
    for (size_t i = 0; i < n; ++i) { put_f64_le(output, i * 8, term); term *= ratio; }
    return (int64_t)(n * 8);
}
