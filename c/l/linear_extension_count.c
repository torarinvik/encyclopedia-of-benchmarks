#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 12, MAX_LENGTH = 14, MAX_STATES = 1 << MAX_N };

int64_t linear_extension_count(const int64_t *input, size_t length) {
    if (input == NULL || length < 1 || length > MAX_LENGTH) return -1;
    const int64_t n_value = input[0];
    if (n_value < 0 || n_value > MAX_N) return -1;
    const size_t n = (size_t)n_value;
    if (length != n + 1) return -1;
    const uint32_t full = (UINT32_C(1) << n) - 1;
    uint32_t predecessor[MAX_N] = {0};
    for (size_t vertex = 0; vertex < n; ++vertex) {
        if (input[1 + vertex] < 0 || (uint64_t)input[1 + vertex] > full) return -1;
        predecessor[vertex] = (uint32_t)input[1 + vertex];
    }

    int64_t ways[MAX_STATES] = {0};
    ways[0] = 1;
    for (uint32_t prefix = 0; prefix <= full; ++prefix) {
        const int64_t count = ways[prefix];
        if (count == 0) continue;
        for (size_t vertex = 0; vertex < n; ++vertex) {
            const uint32_t bit = UINT32_C(1) << vertex;
            if ((prefix & bit) == 0 && (predecessor[vertex] & prefix) == predecessor[vertex])
                ways[prefix | bit] += count;
        }
    }
    return ways[full];
}
