#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_WORDS 130

static void store_i64_le(uint8_t *out, size_t at, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t hypercube_edge_monotonicity_tester(const int64_t *input, size_t length,
                                            uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_WORDS) return -1;
    const int64_t n_value = input[0], q_value = input[1];
    if (n_value < 1 || n_value > 6 || q_value < 1 || q_value > 32) return -1;
    const size_t n = (size_t)n_value, q = (size_t)q_value;
    const size_t domain = (size_t)1 << n;
    if (length != 2 + domain + 2 * q) return -1;
    for (size_t vertex = 0; vertex < domain; ++vertex)
        if (input[2 + vertex] != 0 && input[2 + vertex] != 1) return -1;
    const size_t tape = 2 + domain;
    for (size_t round = 0; round < q; ++round) {
        const int64_t vertex = input[tape + 2 * round];
        const int64_t coordinate = input[tape + 2 * round + 1];
        if (vertex < 0 || (uint64_t)vertex >= domain || coordinate < 0 || (uint64_t)coordinate >= n) return -1;
    }

    int64_t accepted = 1, rounds = 0;
    for (size_t round = 0; round < q; ++round) {
        const size_t vertex = (size_t)input[tape + 2 * round];
        const size_t bit = (size_t)1 << (size_t)input[tape + 2 * round + 1];
        const size_t low = vertex & ~bit, high = low | bit;
        ++rounds;
        if (input[2 + low] > input[2 + high]) { accepted = 0; break; }
    }
    if (output == NULL || capacity < 24) return -2;
    store_i64_le(output, 0, accepted);
    store_i64_le(output, 8, rounds);
    store_i64_le(output, 16, 2 * rounds);
    return 24;
}
