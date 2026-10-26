#include <stddef.h>
#include <stdint.h>

typedef struct { size_t u, v; int64_t weight; int used; } Edge;

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) out[word * 8 + b] = (uint8_t)(bits >> (8 * b));
}

int64_t approximate_matching_greedy(const int64_t *input, size_t length,
                                    uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 98) return -1;
    const int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 12 || m0 < 0 || m0 > 32 || length != 2 + 3 * (size_t)m0) return -1;
    const size_t m = (size_t)m0;
    uint8_t seen[12][12] = {{0}}, matched[12] = {0};
    Edge edges[32] = {{0}};
    for (size_t i = 0; i < m; ++i) {
        int64_t u0 = input[2 + 3*i], v0 = input[3 + 3*i], weight = input[4 + 3*i];
        if (u0 < 0 || u0 >= n0 || v0 < 0 || v0 >= n0 || u0 == v0 || weight < 1 || weight > 100) return -1;
        size_t u = (size_t)u0, v = (size_t)v0;
        size_t lo = u < v ? u : v, hi = u < v ? v : u;
        if (seen[lo][hi]) return -1;
        seen[lo][hi] = 1;
        edges[i] = (Edge){u, v, weight, 0};
    }
    if (!output || capacity < 16) return -2;
    int64_t total = 0;
    uint64_t selected = 0;
    for (size_t step = 0; step < m; ++step) {
        size_t best = m;
        for (size_t i = 0; i < m; ++i)
            if (!edges[i].used && (best == m || edges[i].weight > edges[best].weight)) best = i;
        edges[best].used = 1;
        const Edge edge = edges[best];
        if (!matched[edge.u] && !matched[edge.v]) {
            matched[edge.u] = matched[edge.v] = 1;
            selected |= UINT64_C(1) << best;
            total += edge.weight;
        }
    }
    put_i64(output, 0, total);
    put_i64(output, 1, (int64_t)selected);
    return 16;
}
