#include <stddef.h>
#include <stdint.h>

#define MAX_N 128
#define MAX_Q 32

static size_t lower_bound_i64(const int64_t *a, size_t n, int64_t x) {
    size_t lo = 0, hi = n;
    while (lo < hi) {
        size_t mid = lo + (hi - lo) / 2;
        if (a[mid] < x) lo = mid + 1;
        else hi = mid;
    }
    return lo;
}
static void write_i64_le(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at + b] = (uint8_t)(bits >> (8 * b));
}

int64_t static_range_lis_query(const int64_t *input, size_t length,
                               uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 195) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 1 || q64 > MAX_Q) return -1;
    size_t n = (size_t)n64, q = (size_t)q64;
    if (length != 2 + n + 2 * q) return -1;
    int64_t permutation[MAX_N], left[MAX_Q], right[MAX_Q];
    uint8_t seen[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        int64_t value = input[2 + i];
        if (value < 0 || value >= n64 || seen[value]) return -1;
        seen[value] = 1;
        permutation[i] = value;
    }
    size_t off = 2 + n;
    for (size_t k = 0; k < q; ++k) {
        left[k] = input[off++]; right[k] = input[off++];
        if (left[k] < 0 || left[k] > right[k] || right[k] > n64) return -1;
    }
    int64_t answers[MAX_Q], tails[MAX_N];
    for (size_t k = 0; k < q; ++k) {
        size_t count = 0;
        for (size_t i = (size_t)left[k]; i < (size_t)right[k]; ++i) {
            size_t at = lower_bound_i64(tails, count, permutation[i]);
            tails[at] = permutation[i];
            if (at == count) ++count;
        }
        answers[k] = (int64_t)count;
    }
    size_t bytes = 8 * q;
    if (!output || capacity < bytes) return -2;
    for (size_t k = 0; k < q; ++k) write_i64_le(output, 8 * k, answers[k]);
    return (int64_t)bytes;
}
