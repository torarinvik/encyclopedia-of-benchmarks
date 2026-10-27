/* Clean-room explicit equal-bucket MMPHF profile, Encyclopedia DOI 639. */
#include <stddef.h>
#include <stdint.h>

#define MAX_N 32
#define MAX_Q 32
#define BITS 16
#define BUCKET 3
#define MAX_B ((MAX_N + BUCKET - 1) / BUCKET)
#define MAX_WORDS (3 + MAX_N + 3 * MAX_B + MAX_Q)

static void put_i64(uint8_t *out, size_t pos, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[pos + b] = (uint8_t)(bits >> (8 * b));
}

static int common_prefix(uint16_t a, uint16_t b) {
    int length = 0;
    while (length < BITS && ((a >> (BITS - 1 - length)) & 1u) == ((b >> (BITS - 1 - length)) & 1u)) ++length;
    return length;
}

int64_t mmpfh_bucketing(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > 2 + MAX_N + MAX_Q) return -1;
    int64_t n64 = input[0], q64 = input[1];
    if (n64 < 1 || n64 > MAX_N || q64 < 1 || q64 > MAX_Q || length != 2 + (size_t)n64 + (size_t)q64) return -1;
    size_t n = (size_t)n64, q = (size_t)q64;
    uint16_t keys[MAX_N], queries[MAX_Q];
    for (size_t i = 0; i < n; ++i) {
        int64_t x = input[2 + i];
        if (x < 0 || x > 65535 || (i && input[1 + i] >= x)) return -1;
        keys[i] = (uint16_t)x;
    }
    for (size_t i = 0; i < q; ++i) {
        int64_t x = input[2 + n + i];
        if (x < 0 || x > 65535) return -1;
        queries[i] = (uint16_t)x;
        size_t j = 0;
        while (j < n && keys[j] != queries[i]) ++j;
        if (j == n) return -1;
    }
    size_t buckets = (n + BUCKET - 1) / BUCKET;
    int64_t d0[MAX_N], d1_len[MAX_B], d1_value[MAX_B], ranks[MAX_Q];
    for (size_t b = 0; b < buckets; ++b) {
        size_t start = b * BUCKET, end = start + BUCKET;
        if (end > n) end = n;
        int lp = end - start == 1 ? BITS : common_prefix(keys[start], keys[end - 1]);
        uint16_t prefix = lp == 0 ? 0 : (uint16_t)(keys[start] >> (BITS - lp));
        d1_len[b] = lp; d1_value[b] = prefix;
        for (size_t i = start; i < end; ++i) d0[i] = lp;
    }
    for (size_t i = 0; i < q; ++i) {
        size_t pos = 0;
        while (keys[pos] != queries[i]) ++pos;
        int lp = (int)d0[pos];
        uint16_t prefix = lp == 0 ? 0 : (uint16_t)(queries[i] >> (BITS - lp));
        size_t b = 0;
        while (b < buckets && (d1_len[b] != lp || d1_value[b] != prefix)) ++b;
        if (b == buckets) return -1;
        ranks[i] = (int64_t)(b * BUCKET + pos - b * BUCKET);
    }
    size_t words = 3 + n + 3 * buckets + q;
    if (output == NULL || capacity < words * 8) return -2;
    int64_t staged[MAX_WORDS];
    size_t k = 0;
    staged[k++] = (int64_t)n; staged[k++] = (int64_t)buckets; staged[k++] = (int64_t)q;
    for (size_t i = 0; i < n; ++i) staged[k++] = d0[i];
    for (size_t b = 0; b < buckets; ++b) { staged[k++] = d1_len[b]; staged[k++] = d1_value[b]; staged[k++] = (int64_t)b; }
    for (size_t i = 0; i < q; ++i) staged[k++] = ranks[i];
    for (size_t i = 0; i < words; ++i) put_i64(output, i * 8, staged[i]);
    return (int64_t)(words * 8);
}
