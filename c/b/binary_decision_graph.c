#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t at, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[at * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t binary_decision_graph(const int64_t *input, size_t length,
                              uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 65) return -1;
    int64_t nv = input[0];
    if (nv < 1 || nv > 6 || length != 1u + ((size_t)1 << (unsigned)nv)) return -1;
    size_t n = (size_t)nv, count = (size_t)1 << n;
    int64_t ids[64], next[64];
    for (size_t i = 0; i < count; ++i) {
        if (input[1 + i] != 0 && input[1 + i] != 1) return -1;
        ids[i] = input[1 + i];
    }
    int64_t vars[63], lows[63], highs[63];
    size_t nodes = 0, current_count = count;
    for (size_t step = 0; step < n; ++step) {
        size_t var = n - 1 - step, next_count = current_count / 2;
        for (size_t p = 0; p < next_count; ++p) {
            int64_t lo = ids[2 * p], hi = ids[2 * p + 1];
            if (lo == hi) { next[p] = lo; continue; }
            size_t found = nodes;
            for (size_t j = nodes; j > 0; --j) {
                size_t k = j - 1;
                if ((size_t)vars[k] != var) break;
                if (lows[k] == lo && highs[k] == hi) { found = k; break; }
            }
            if (found == nodes) {
                vars[nodes] = (int64_t)var; lows[nodes] = lo; highs[nodes] = hi;
                next[p] = (int64_t)(2 + nodes); ++nodes;
            } else next[p] = (int64_t)(2 + found);
        }
        for (size_t p = 0; p < next_count; ++p) ids[p] = next[p];
        current_count = next_count;
    }
    size_t bytes = 8 * (2 + 3 * nodes);
    if (output == NULL || capacity < bytes) return -2;
    put_i64(output, 0, ids[0]); put_i64(output, 1, (int64_t)nodes);
    for (size_t i = 0; i < nodes; ++i) {
        put_i64(output, 2 + 3 * i, vars[i]);
        put_i64(output, 3 + 3 * i, lows[i]);
        put_i64(output, 4 + 3 * i, highs[i]);
    }
    return (int64_t)bytes;
}
