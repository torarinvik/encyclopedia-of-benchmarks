#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 5, MAX_SIZE = 32, MAX_INPUT = 33 };
static const int64_t MODULUS = INT64_C(998244353);

static int subset_size(size_t mask) {
    int count = 0;
    while (mask != 0) {
        count += (int)(mask & 1U);
        mask >>= 1;
    }
    return count;
}

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t exp_of_set_power_series(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N) return -1;
    const size_t n = (size_t)input[0];
    const size_t size = (size_t)1 << n;
    if (length != 1 + size || input[1] != 0) return -1;
    for (size_t mask = 0; mask < size; ++mask)
        if (input[1 + mask] < 0 || input[1 + mask] >= MODULUS) return -1;

    const size_t bytes = 8 * size;
    if (output == NULL || capacity < bytes) return -2;

    int64_t inverse[MAX_N + 1] = {0};
    int64_t result[MAX_SIZE] = {0};
    if (n > 0) inverse[1] = 1;
    for (size_t k = 2; k <= n; ++k)
        inverse[k] = MODULUS - (MODULUS / (int64_t)k) *
                     inverse[(size_t)(MODULUS % (int64_t)k)] % MODULUS;
    result[0] = 1;
    for (size_t mask = 1; mask < size; ++mask) {
        int64_t total = 0;
        for (size_t subset = mask; subset != 0; subset = (subset - 1) & mask) {
            int64_t term = (int64_t)subset_size(subset) * input[1 + subset] % MODULUS;
            term = term * result[mask ^ subset] % MODULUS;
            total = (total + term) % MODULUS;
        }
        result[mask] = total * inverse[(size_t)subset_size(mask)] % MODULUS;
    }
    for (size_t mask = 0; mask < size; ++mask) store_le(output, 8 * mask, result[mask]);
    return (int64_t)bytes;
}
