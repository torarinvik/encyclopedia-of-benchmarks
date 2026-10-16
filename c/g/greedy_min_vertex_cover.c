#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16

static int bit_count(uint64_t value)
{
    int count = 0;
    while (value != 0) {
        value &= value - 1;
        ++count;
    }
    return count;
}

int64_t greedy_min_vertex_cover(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_VERTICES + 1) return -1;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_VERTICES || length != (size_t)count_value + 1) return -1;
    const int count = (int)count_value;
    const uint64_t limit = (UINT64_C(1) << count) - 1;
    uint64_t neighbors[MAX_VERTICES] = {0};
    for (int vertex = 0; vertex < count; ++vertex) {
        const int64_t mask_value = values[vertex + 1];
        if (mask_value < 0 || (uint64_t)mask_value > limit) return -1;
        const uint64_t mask = (uint64_t)mask_value;
        if (mask & (UINT64_C(1) << vertex)) return -1;
        neighbors[vertex] = mask;
    }
    for (int vertex = 0; vertex < count; ++vertex)
        for (int other = vertex + 1; other < count; ++other)
            if (((neighbors[vertex] >> other) & 1) != ((neighbors[other] >> vertex) & 1)) return -1;

    uint64_t chosen = 0;
    for (;;) {
        int best_vertex = -1, best_degree = 0;
        for (int vertex = 0; vertex < count; ++vertex) {
            const int degree = bit_count(neighbors[vertex]);
            if (degree > best_degree) { best_vertex = vertex; best_degree = degree; }
        }
        if (best_vertex < 0) return (int64_t)chosen;
        const uint64_t bit = UINT64_C(1) << best_vertex;
        chosen |= bit;
        for (int vertex = 0; vertex < count; ++vertex) neighbors[vertex] &= ~bit;
        neighbors[best_vertex] = 0;
    }
}
