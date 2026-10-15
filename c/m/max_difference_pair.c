/* Recursive maximum-difference pair, matching the pinned Python tie order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
typedef struct { int64_t small, big; } pair_t;

static pair_t solve(const int64_t *values, size_t n) {
    if (n == 1) return (pair_t){values[0], values[0]};
    size_t left_n = n / 2;
    pair_t left = solve(values, left_n);
    pair_t right = solve(values + left_n, n - left_n);
    int64_t min_left = values[0], max_right = values[left_n];
    for (size_t i = 1; i < left_n; ++i) if (values[i] < min_left) min_left = values[i];
    for (size_t i = left_n + 1; i < n; ++i) if (values[i] > max_right) max_right = values[i];
    int64_t cross_difference = max_right - min_left;
    int64_t right_difference = right.big - right.small;
    int64_t left_difference = left.big - left.small;
    if (right_difference > cross_difference && right_difference > left_difference) return right;
    if (left_difference > cross_difference) return left;
    return (pair_t){min_left, max_right};
}

static void put_i64_le(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[offset + b] = (uint8_t)(bits >> (8 * b));
}

int64_t max_difference_pair(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (!input || length < 2 || input[0] < 1 || input[0] > MAX_N || length != (size_t)input[0] + 1) return -1;
    size_t n = (size_t)input[0];
    for (size_t i = 0; i < n; ++i) if (input[i + 1] < -1000000 || input[i + 1] > 1000000) return -1;
    if (capacity < 16 || !output) return -2;
    pair_t result = solve(input + 1, n);
    put_i64_le(output, 0, result.small);
    put_i64_le(output, 8, result.big);
    return 16;
}
