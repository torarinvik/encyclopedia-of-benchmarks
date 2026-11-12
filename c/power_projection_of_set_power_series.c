#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 4, MAX_M = 8, MAX_SIZE = 16, MAX_INPUT = 35 };
static const int64_t MODULUS = INT64_C(998244353);

static void store_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t power_projection_of_set_power_series(
    const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > MAX_N || input[1] < 0 || input[1] > MAX_M) return -1;
    const size_t n = (size_t)input[0];
    const size_t powers = (size_t)input[1];
    const size_t size = (size_t)1 << n;
    if (length != 2 + 2 * size) return -1;

    int64_t series[MAX_SIZE] = {0};
    int64_t weights[MAX_SIZE] = {0};
    for (size_t mask = 0; mask < size; ++mask) {
        const int64_t a = input[2 + mask];
        const int64_t w = input[2 + size + mask];
        if (a < 0 || a >= MODULUS || w < 0 || w >= MODULUS) return -1;
        series[mask] = a;
        weights[mask] = w;
    }

    const size_t bytes = 8 * powers;
    if (output == NULL || capacity < bytes) return -2;

    int64_t current_storage[MAX_SIZE] = {0};
    int64_t next_storage[MAX_SIZE] = {0};
    int64_t *current = current_storage;
    int64_t *next = next_storage;
    current[0] = 1;
    for (size_t power = 0; power < powers; ++power) {
        int64_t projection = 0;
        for (size_t mask = 0; mask < size; ++mask)
            projection = (projection + weights[mask] * current[mask]) % MODULUS;
        store_le(output, 8 * power, projection);
        if (power + 1 == powers) break;

        for (size_t mask = 0; mask < size; ++mask) {
            int64_t total = 0;
            size_t subset = mask;
            for (;;) {
                total = (total + current[subset] * series[mask ^ subset]) % MODULUS;
                if (subset == 0) break;
                subset = (subset - 1) & mask;
            }
            next[mask] = total;
        }
        int64_t *temporary = current;
        current = next;
        next = temporary;
    }
    return (int64_t)bytes;
}
