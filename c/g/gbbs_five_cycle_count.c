/* Clean-room bounded GBBS five-cycle profile; see package LICENSE.txt. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_M = 64, MAX_INPUT = 2 + 2 * MAX_M };

static void store_i64_le(uint8_t *output, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t gbbs_five_cycle_count(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        length != 2 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[2 + 2 * edge], v64 = input[3 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacent[u][v]) return -1;
        adjacent[u][v] = adjacent[v][u] = 1;
    }
    if (output == NULL || capacity < 8) return -2;

    int64_t count = 0;
    for (size_t start = 0; start < n; ++start)
        for (size_t first = start + 1; first < n; ++first)
            for (size_t second = start + 1; second < n; ++second) {
                if (second == first) continue;
                for (size_t third = start + 1; third < n; ++third) {
                    if (third == first || third == second) continue;
                    for (size_t last = first + 1; last < n; ++last) {
                        if (last == second || last == third) continue;
                        if (adjacent[start][first] && adjacent[first][second] &&
                            adjacent[second][third] && adjacent[third][last] &&
                            adjacent[last][start]) ++count;
                    }
                }
            }
    store_i64_le(output, count);
    return 8;
}
