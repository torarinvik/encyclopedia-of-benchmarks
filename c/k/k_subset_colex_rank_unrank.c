#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_K = 16, MAX_OUTPUT_WORDS = 17 };

static int64_t choose_small(int n, int k) {
    if (n < 0 || k < 0 || k > n) return 0;
    if (k > n - k) k = n - k;
    int64_t value = 1;
    for (int i = 1; i <= k; ++i) value = value * (n - k + i) / i;
    return value;
}

static void store_i64_le(uint8_t *out, size_t index, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[index * 8 + byte] = (uint8_t)(bits & 255u);
        bits >>= 8;
    }
}

int64_t k_subset_colex_rank_unrank(const int64_t *input, size_t length,
        uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > 20) return -1;
    int64_t mode = input[0];
    if (mode < 0 || mode > 1 || length < 3) return -1;
    int64_t raw_n = input[1], raw_k = input[2];
    if (raw_n < 0 || raw_n > MAX_N || raw_k < 0 || raw_k > raw_n) return -1;
    int n = (int)raw_n, k = (int)raw_k;
    int64_t indices[MAX_K] = {0};
    int64_t rank = 0;

    if (mode == 0) {
        if (length != (size_t)(3 + k)) return -1;
        for (int i = 0; i < k; ++i) {
            int64_t index = input[3 + (size_t)i];
            if (index < 0 || index >= n || (i > 0 && indices[i - 1] >= index)) return -1;
            indices[i] = index;
            rank += choose_small((int)index, i + 1);
        }
    } else {
        if (length != 4) return -1;
        rank = input[3];
        int64_t count = choose_small(n, k);
        if (rank < 0 || rank >= count) return -1;
        int upper = n - 1;
        int64_t remainder = rank;
        for (int order = k; order >= 1; --order) {
            int candidate = upper;
            while (candidate >= 0 && choose_small(candidate, order) > remainder) --candidate;
            if (candidate < 0) return -1;
            indices[order - 1] = candidate;
            remainder -= choose_small(candidate, order);
            upper = candidate - 1;
        }
    }

    size_t words = (size_t)k + 1;
    if (output == NULL || capacity < words * 8) return -2;
    store_i64_le(output, 0, rank);
    for (int i = 0; i < k; ++i) store_i64_le(output, (size_t)i + 1, indices[i]);
    return (int64_t)(words * 8);
}
