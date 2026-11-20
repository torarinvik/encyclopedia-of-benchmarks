#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 6, MAX_Q = 32, MAX_INPUT = 130, MAX_OUTPUT = 24 };

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t blr_linearity_test(const int64_t *values, size_t length,
                           uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > MAX_INPUT) return -1;
    if (values[0] < 1 || values[0] > MAX_N || values[1] < 1 || values[1] > MAX_Q) return -1;
    const size_t n = (size_t)values[0], q = (size_t)values[1];
    const size_t domain = (size_t)1 << n;
    if (length != 2 + domain + 2 * q) return -1;
    const int64_t *table = values + 2;
    const int64_t *tape = table + domain;
    for (size_t i = 0; i < domain; ++i)
        if (table[i] != 0 && table[i] != 1) return -1;
    for (size_t i = 0; i < 2 * q; ++i)
        if (tape[i] < 0 || (uint64_t)tape[i] >= domain) return -1;

    size_t rounds = 0;
    int64_t accepted = 1;
    for (size_t round = 0; round < q; ++round) {
        const size_t x = (size_t)tape[2 * round];
        const size_t y = (size_t)tape[2 * round + 1];
        ++rounds;
        if ((table[x] ^ table[y]) != table[x ^ y]) { accepted = 0; break; }
    }
    if (output == NULL || capacity < MAX_OUTPUT) return -2;
    uint8_t staged[MAX_OUTPUT];
    put_i64(staged, 0, accepted);
    put_i64(staged, 8, (int64_t)rounds);
    put_i64(staged, 16, (int64_t)(3 * rounds));
    for (size_t i = 0; i < MAX_OUTPUT; ++i) output[i] = staged[i];
    return MAX_OUTPUT;
}
