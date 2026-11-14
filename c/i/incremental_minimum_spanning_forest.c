#include <stddef.h>
#include <stdint.h>

int64_t incremental_minimum_spanning_forest(const int64_t *input, size_t length,
                                             uint8_t *output, size_t capacity) {
    if (!input || length < 2 || length > 98) return -1;
    int64_t n0 = input[0], m0 = input[1];
    if (n0 < 1 || n0 > 16 || m0 < 1 || m0 > 32 || length != 2 + 3 * (size_t)m0) return -1;
    size_t n = (size_t)n0, m = (size_t)m0;
    for (size_t i = 0; i < m; ++i) {
        int64_t u = input[2 + 3*i], v = input[3 + 3*i], w = input[4 + 3*i];
        if (u < 0 || u >= n0 || v < 0 || v >= n0 || w < 1 || w > 1000000) return -1;
        for (size_t j = 0; j < i; ++j) if (input[4 + 3*j] == w) return -1;
    }
    int active[32] = {0};
    int64_t answers[32];
    for (size_t edge = 0; edge < m; ++edge) {
        int start = (int)input[2 + 3*edge], target = (int)input[3 + 3*edge];
        if (start == target) { answers[edge] = (int64_t)edge; continue; }
        int parent[16], parent_edge[16], queue[16];
        for (size_t i = 0; i < n; ++i) { parent[i] = -1; parent_edge[i] = -1; }
        size_t head = 0, tail = 0;
        queue[tail++] = start; parent[start] = start;
        while (head < tail) {
            int vertex = queue[head++];
            for (size_t i = 0; i < edge; ++i) {
                if (!active[i]) continue;
                int u = (int)input[2 + 3*i], v = (int)input[3 + 3*i];
                int neighbor = u == vertex ? v : (v == vertex ? u : -1);
                if (neighbor >= 0 && parent[neighbor] < 0) {
                    parent[neighbor] = vertex; parent_edge[neighbor] = (int)i;
                    queue[tail++] = neighbor;
                }
            }
        }
        if (parent[target] < 0) { active[edge] = 1; answers[edge] = -1; continue; }
        int heaviest = -1;
        for (int vertex = target; vertex != start; vertex = parent[vertex]) {
            int i = parent_edge[vertex];
            if (heaviest < 0 || input[4 + 3*i] > input[4 + 3*heaviest]) heaviest = i;
        }
        if (input[4 + 3*edge] < input[4 + 3*heaviest]) {
            active[heaviest] = 0; active[edge] = 1; answers[edge] = heaviest;
        } else answers[edge] = (int64_t)edge;
    }
    size_t bytes = 8 * m;
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < m; ++i) {
        uint64_t bits = (uint64_t)answers[i];
        for (size_t b = 0; b < 8; ++b) output[8*i+b] = (uint8_t)(bits >> (8*b));
    }
    return (int64_t)bytes;
}
