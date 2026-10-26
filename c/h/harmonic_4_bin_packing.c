#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_INPUT 33
#define CAPACITY 10000

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { out[offset + byte] = (uint8_t)(bits & 255U); bits >>= 8; }
}

int64_t harmonic_4_bin_packing(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0];
    if (n64 < 1 || n64 > MAX_N || length != (size_t)(1 + n64)) return -1;
    const size_t n = (size_t)n64;
    int64_t current[4] = {-1, -1, -1, -1}, remaining[4] = {0, 0, 0, 0};
    int64_t assignment[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        const int64_t size = input[1 + i];
        if (size < 1 || size > CAPACITY) return -1;
    }
    const size_t output_bytes = 8 * (n + 1);
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t bins = 0;
    for (size_t i = 0; i < n; ++i) {
        const int64_t size = input[1 + i];
        size_t kind = size * 2 > CAPACITY ? 0 : size * 3 > CAPACITY ? 1 : size * 4 > CAPACITY ? 2 : 3;
        if (current[kind] < 0 || size > remaining[kind]) {
            current[kind] = bins++;
            remaining[kind] = CAPACITY;
        }
        assignment[i] = current[kind];
        remaining[kind] -= size;
    }
    store_i64_le(output, 0, bins);
    for (size_t i = 0; i < n; ++i) store_i64_le(output, 8 * (i + 1), assignment[i]);
    return (int64_t)output_bytes;
}
