#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 512
#define FNV_OFFSET_BASIS UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t fnv_word(uint64_t hash, int64_t value)
{
    const uint64_t bits = (uint64_t)value;
    for (unsigned byte = 0; byte < 8; ++byte) {
        hash ^= (bits >> (8 * byte)) & UINT64_C(0xff);
        hash *= FNV_PRIME;
    }
    return hash;
}

int64_t kasai_algorithm(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || values[0] < 0 || values[0] > MAX_LENGTH) return -1;
    const size_t n = (size_t)values[0];
    if (length != 1 + 2 * n) return -1;
    for (size_t i = 0; i < n; ++i)
        if (values[1 + i] < 0 || values[1 + i] > 127) return -1;

    size_t suffixes[MAX_LENGTH];
    size_t rank[MAX_LENGTH];
    bool seen[MAX_LENGTH] = {false};
    int64_t lcp[MAX_LENGTH] = {0};
    for (size_t position = 0; position < n; ++position) {
        const int64_t suffix_value = values[1 + n + position];
        if (suffix_value < 0 || (uint64_t)suffix_value >= n) return -1;
        const size_t suffix = (size_t)suffix_value;
        if (seen[suffix]) return -1;
        seen[suffix] = true;
        suffixes[position] = suffix;
        rank[suffix] = position;
    }

    for (size_t position = 1; position < n; ++position) {
        const size_t left = suffixes[position - 1];
        const size_t right = suffixes[position];
        const int64_t left_tail_rank = left + 1 < n ? (int64_t)rank[left + 1] : -1;
        const int64_t right_tail_rank = right + 1 < n ? (int64_t)rank[right + 1] : -1;
        const int64_t left_byte = values[1 + left];
        const int64_t right_byte = values[1 + right];
        if (left_byte > right_byte ||
            (left_byte == right_byte && left_tail_rank >= right_tail_rank)) return -1;
    }

    size_t common = 0;
    for (size_t start = 0; start < n; ++start) {
        const size_t current_rank = rank[start];
        if (current_rank == n - 1) {
            common = 0;
            continue;
        }
        const size_t next_start = suffixes[current_rank + 1];
        while (start + common < n && next_start + common < n &&
               values[1 + start + common] == values[1 + next_start + common]) ++common;
        lcp[current_rank] = (int64_t)common;
        if (common > 0) --common;
    }

    uint64_t hash = fnv_word(FNV_OFFSET_BASIS, (int64_t)n);
    for (size_t i = 0; i < n; ++i) hash = fnv_word(hash, lcp[i]);
    return (int64_t)(hash & INT64_MAX);
}
