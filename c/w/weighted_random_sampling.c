#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_INPUT 50

static int64_t pow_small(int64_t base, int64_t exponent) {
    int64_t result = 1;
    for (int64_t i = 0; i < exponent; ++i) result *= base;
    return result;
}

static int before(const int64_t *weights, const int64_t *numerators,
                  const int64_t *denominators, int64_t left, int64_t right) {
    int64_t lhs = pow_small(numerators[left], weights[right]) *
                  pow_small(denominators[right], weights[left]);
    int64_t rhs = pow_small(numerators[right], weights[left]) *
                  pow_small(denominators[left], weights[right]);
    return lhs > rhs || (lhs == rhs && left < right);
}

static void put64(uint8_t *out, size_t pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t j = 0; j < 8; ++j) {
        out[pos + j] = (uint8_t)(bits & 255U);
        bits >>= 8;
    }
}

int64_t weighted_random_sampling(const int64_t *input, size_t length,
                                 uint8_t *output, size_t capacity) {
    if (!input || length < 5 || length > MAX_INPUT) return -1;
    int64_t n64 = input[0], count64 = input[1];
    if (n64 < 1 || n64 > MAX_N || count64 < 1 || count64 > n64 ||
        length != 2 + 3 * (size_t)n64) return -1;
    size_t n = (size_t)n64, count = (size_t)count64;
    int64_t weights[MAX_N], numerators[MAX_N], denominators[MAX_N];
    for (size_t i = 0; i < n; ++i) {
        weights[i] = input[2 + 3 * i];
        numerators[i] = input[3 + 3 * i];
        denominators[i] = input[4 + 3 * i];
        if (weights[i] < 1 || weights[i] > 3 || numerators[i] < 1 ||
            numerators[i] >= denominators[i] || denominators[i] > 100) return -1;
    }
    size_t bytes = 8 * count;
    if (!output || capacity < bytes) return -2;
    int64_t available[MAX_N], selected[MAX_N];
    for (size_t i = 0; i < n; ++i) available[i] = (int64_t)i;
    for (size_t rank = 0; rank < count; ++rank) {
        size_t best = 0;
        for (size_t i = 1; i < n - rank; ++i)
            if (before(weights, numerators, denominators, available[i], available[best])) best = i;
        selected[rank] = available[best];
        for (size_t i = best; i + 1 < n - rank; ++i) available[i] = available[i + 1];
    }
    for (size_t i = 0; i < count; ++i) put64(output, 8 * i, selected[i]);
    return (int64_t)bytes;
}
