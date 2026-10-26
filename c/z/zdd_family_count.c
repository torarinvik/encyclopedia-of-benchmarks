#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t zdd_family_count(const int64_t *input, size_t length,
                         uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 34) return -1;
    int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 6 || m0 < 0 || m0 > 32 || length != (size_t)m0 + 2) return -1;
    size_t n = (size_t)n0, limit = (size_t)1 << n, m = (size_t)m0;
    int64_t ids[64] = {0}, next[64] = {0}, vars[63] = {0}, lows[63] = {0}, highs[63] = {0};
    int64_t counts[65] = {0, 1};
    uint8_t seen[64] = {0};
    for (size_t i = 0; i < m; ++i) {
        int64_t mask = input[2 + i];
        if (mask < 0 || (uint64_t)mask >= limit || seen[(size_t)mask]) return -1;
        seen[(size_t)mask] = 1; ids[(size_t)mask] = 1;
    }
    size_t nodes = 0, current_count = limit;
    for (size_t variable = 0; variable < n; ++variable) {
        size_t next_count = current_count / 2;
        for (size_t p = 0; p < next_count; ++p) {
            int64_t low = ids[2 * p], high = ids[2 * p + 1];
            if (high == 0) { next[p] = low; continue; }
            size_t found = nodes;
            for (size_t j = nodes; j > 0; --j) {
                size_t k = j - 1;
                if ((size_t)vars[k] != variable) break;
                if (lows[k] == low && highs[k] == high) { found = k; break; }
            }
            if (found == nodes) {
                vars[nodes] = (int64_t)variable; lows[nodes] = low; highs[nodes] = high;
                counts[2 + nodes] = counts[low] + counts[high];
                next[p] = (int64_t)(2 + nodes++);
            } else next[p] = (int64_t)(2 + found);
        }
        for (size_t p = 0; p < next_count; ++p) ids[p] = next[p];
        current_count = next_count;
    }
    size_t bytes = 8 * (3 + 3 * nodes);
    if (!output || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, (int64_t)nodes); put_i64(output, 2, counts[ids[0]]);
    for (size_t i = 0; i < nodes; ++i) {
        put_i64(output, 3 + 3 * i, vars[i]); put_i64(output, 4 + 3 * i, lows[i]); put_i64(output, 5 + 3 * i, highs[i]);
    }
    return (int64_t)bytes;
}
