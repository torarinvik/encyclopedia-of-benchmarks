#include <stddef.h>
#include <stdint.h>

#define MAX_N 4096
#define FNV_OFFSET UINT64_C(14695981039346656037)
#define FNV_PRIME UINT64_C(1099511628211)

static uint64_t hash_i32(uint64_t hash, int64_t value) {
    uint32_t bits = (uint32_t)(int32_t)value;
    for (unsigned shift = 0; shift < 32; shift += 8) {
        hash = (hash ^ (uint8_t)(bits >> shift)) * FNV_PRIME;
    }
    return hash;
}

int64_t monotonic_queue(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_N + 2) return -1;
    const int64_t n64 = input[0], window64 = input[1];
    if (n64 < 1 || n64 > MAX_N || window64 < 1 || window64 > n64 || length != (size_t)n64 + 2) return -1;
    const size_t n = (size_t)n64, window = (size_t)window64;
    for (size_t i = 0; i < n; ++i) if (input[2 + i] < INT32_MIN || input[2 + i] > INT32_MAX) return -1;
    size_t deque[MAX_N], head = 0, tail = 0;
    uint64_t hash = FNV_OFFSET;
    for (size_t i = 0; i < n; ++i) {
        while (head < tail && deque[head] + window <= i) ++head;
        while (head < tail && input[2 + deque[tail - 1]] <= input[2 + i]) --tail;
        deque[tail++] = i;
        if (i + 1 >= window) hash = hash_i32(hash, input[2 + deque[head]]);
    }
    return (int64_t)(hash & UINT64_C(0x7fffffffffffffff));
}
