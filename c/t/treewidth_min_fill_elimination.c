#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 16, MAX_EDGES = 120, MAX_INPUT = 242, MAX_OUTPUT = 2064 };

static void put_i64(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) { output[offset + byte] = (uint8_t)bits; bits >>= 8; }
}

int64_t treewidth_min_fill_elimination(const int64_t *values, size_t length,
                                       uint8_t *output, size_t capacity)
{
    if (!values || length < 2 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_N ||
        values[1] < 0 || values[1] > MAX_EDGES) return -1;
    const int n = (int)values[0], m = (int)values[1];
    if (m > n * (n - 1) / 2 || length != (size_t)(2 + 2 * m)) return -1;
    uint8_t adjacent[MAX_N][MAX_N] = {{0}};
    for (int edge = 0; edge < m; ++edge) {
        const int64_t a = values[2 + 2 * edge], b = values[3 + 2 * edge];
        if (a < 0 || b < 0 || a >= n || b >= n || a >= b || adjacent[a][b]) return -1;
        adjacent[a][b] = adjacent[b][a] = 1;
    }
    uint8_t active[MAX_N] = {0};
    int64_t order[MAX_N] = {0}, fill_u[MAX_EDGES] = {0}, fill_v[MAX_EDGES] = {0};
    for (int i = 0; i < n; ++i) active[i] = 1;
    int width = 0, fill_count = 0;
    for (int step = 0; step < n; ++step) {
        int chosen = -1, chosen_fill = MAX_EDGES + 1, chosen_degree = 0;
        for (int vertex = 0; vertex < n; ++vertex) if (active[vertex]) {
            int neighbors[MAX_N], count = 0;
            for (int other = 0; other < n; ++other)
                if (active[other] && adjacent[vertex][other]) neighbors[count++] = other;
            int fill = 0;
            for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j)
                fill += !adjacent[neighbors[i]][neighbors[j]];
            if (fill < chosen_fill) { chosen = vertex; chosen_fill = fill; chosen_degree = count; }
        }
        order[step] = chosen;
        if (chosen_degree > width) width = chosen_degree;
        int neighbors[MAX_N], count = 0;
        for (int other = 0; other < n; ++other)
            if (active[other] && adjacent[chosen][other]) neighbors[count++] = other;
        for (int i = 0; i < count; ++i) for (int j = i + 1; j < count; ++j) {
            const int a = neighbors[i], b = neighbors[j];
            if (!adjacent[a][b]) {
                adjacent[a][b] = adjacent[b][a] = 1;
                fill_u[fill_count] = a;
                fill_v[fill_count] = b;
                ++fill_count;
            }
        }
        active[chosen] = 0;
    }
    const size_t bytes = 8 * ((size_t)n + 2 + 2 * (size_t)fill_count);
    uint8_t staged[MAX_OUTPUT] = {0};
    put_i64(staged, 0, width);
    for (int i = 0; i < n; ++i) put_i64(staged, 8 * (size_t)(i + 1), order[i]);
    put_i64(staged, 8 * (size_t)(n + 1), fill_count);
    for (int i = 0; i < fill_count; ++i) {
        put_i64(staged, 8 * (size_t)(n + 2 + 2 * i), fill_u[i]);
        put_i64(staged, 8 * (size_t)(n + 3 + 2 * i), fill_v[i]);
    }
    if (!output || capacity < bytes) return -2;
    for (size_t i = 0; i < bytes; ++i) output[i] = staged[i];
    return (int64_t)bytes;
}
