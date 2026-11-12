#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 8, MAX_SIZE = 1 << MAX_N, MAX_INPUT = 1 + 2 * MAX_SIZE };
static const int64_t MODULUS = 998244353;

static void store_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t bitwise_or_convolution(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT) return -1;
    int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    size_t n = (size_t)n_value, size = (size_t)1 << n;
    if (length != 1 + 2 * size) return -1;
    for (size_t i = 0; i < 2 * size; ++i)
        if (input[1 + i] < 0 || input[1 + i] >= MODULUS) return -1;
    size_t bytes = 8 * size;
    if (output == NULL || capacity < bytes) return -2;

    int64_t a[MAX_SIZE] = {0}, b[MAX_SIZE] = {0};
    for (size_t i = 0; i < size; ++i) {
        a[i] = input[1 + i];
        b[i] = input[1 + size + i];
    }
    for (size_t bit = 0; bit < n; ++bit) {
        size_t bit_mask = (size_t)1 << bit;
        for (size_t mask = 0; mask < size; ++mask) {
            if (mask & bit_mask) {
                a[mask] = (a[mask] + a[mask ^ bit_mask]) % MODULUS;
                b[mask] = (b[mask] + b[mask ^ bit_mask]) % MODULUS;
            }
        }
    }
    for (size_t i = 0; i < size; ++i) a[i] = (a[i] * b[i]) % MODULUS;
    for (size_t bit = 0; bit < n; ++bit) {
        size_t bit_mask = (size_t)1 << bit;
        for (size_t mask = 0; mask < size; ++mask) {
            if (mask & bit_mask) {
                a[mask] -= a[mask ^ bit_mask];
                if (a[mask] < 0) a[mask] += MODULUS;
            }
        }
    }
    for (size_t i = 0; i < size; ++i) store_i64_le(output, 8 * i, a[i]);
    return (int64_t)bytes;
}
