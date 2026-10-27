#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 32, MAX_INPUT = 67, MAX_OUTPUT = 16 };

static void put_u64(uint8_t *output, size_t word, uint64_t value) {
    for (size_t byte = 0; byte < 8; ++byte)
        output[word * 8 + byte] = (uint8_t)(value >> (8 * byte));
}

int64_t psi_suffix_array_access(const int64_t *input, size_t length,
                                uint8_t *output, size_t capacity) {
    if (input == NULL || length < 5 || length > MAX_INPUT) return -1;
    const int64_t n0 = input[0], query0 = input[1], stride0 = input[2];
    if (n0 < 1 || n0 > MAX_N || query0 < 0 || query0 >= n0 || stride0 < 1 || stride0 > n0 ||
        length != 3 + 2 * (size_t)n0) return -1;
    const size_t n = (size_t)n0, query = (size_t)query0, stride = (size_t)stride0;
    uint8_t destinations[MAX_N] = {0}, visited[MAX_N] = {0};
    for (size_t i = 0; i < n; ++i) {
        const int64_t next = input[3 + i];
        if (next < 0 || (uint64_t)next >= n || destinations[(size_t)next]) return -1;
        destinations[(size_t)next] = 1;
        const int64_t sample = input[3 + n + i];
        if (sample < 0 || sample > n) return -1;
    }
    size_t anchor = n;
    for (size_t i = 0; i < n; ++i)
        if (input[3 + n + i] != 0) { anchor = i; break; }
    if (anchor == n) return -1;
    const int64_t anchor_value = input[3 + n + anchor];
    if ((anchor_value - 1) % stride0 != 0) return -1;
    uint64_t full_sa[MAX_N] = {0};
    size_t rank = anchor;
    int64_t value = anchor_value;
    for (size_t step = 0; step < n; ++step) {
        if (visited[rank]) return -1;
        visited[rank] = 1;
        full_sa[rank] = (uint64_t)value;
        rank = (size_t)input[3 + rank];
        value = value == n0 ? 1 : value + 1;
    }
    if (rank != anchor || value != anchor_value) return -1;
    for (size_t i = 0; i < n; ++i) {
        const int64_t expected = (full_sa[i] - 1) % stride == 0 ? (int64_t)full_sa[i] : 0;
        if (input[3 + n + i] != expected) return -1;
    }
    rank = query;
    size_t hops = 0;
    while (input[3 + n + rank] == 0) {
        rank = (size_t)input[3 + rank];
        if (++hops >= stride) return -1;
    }
    int64_t position0 = input[3 + n + rank] - 1 - (int64_t)hops;
    position0 %= n0;
    if (position0 < 0) position0 += n0;
    if (output == NULL || capacity < MAX_OUTPUT) return -2;
    put_u64(output, 0, (uint64_t)(position0 + 1));
    put_u64(output, 1, (uint64_t)hops);
    return MAX_OUTPUT;
}
