#include <stddef.h>
#include <stdint.h>

enum { MAX_N = 64, MAX_Q = 16, MAX_INPUT = 82 };

static int has_edge(int64_t row, size_t vertex) {
    return (int)(((uint64_t)row >> vertex) & UINT64_C(1));
}

static void put_i64(uint8_t *out, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        out[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t dense_graph_bipartiteness_tester(const int64_t *values, size_t length,
                                        uint8_t *output, size_t capacity) {
    if (!values || length < 4 || length > MAX_INPUT || values[0] < 1 || values[0] > MAX_N ||
        values[1] < 1 || values[1] > MAX_Q) return -1;
    const size_t n = (size_t)values[0], q = (size_t)values[1];
    if (q > n || length != 2 + n + q) return -1;
    const int64_t *rows = values + 2;
    const int64_t *draws = rows + n;
    for (size_t i = 0; i < n; ++i) {
        if ((n < 64 && (rows[i] < 0 || ((uint64_t)rows[i] >> n) != 0)) || has_edge(rows[i], i)) return -1;
        for (size_t j = i + 1; j < n; ++j)
            if (has_edge(rows[i], j) != has_edge(rows[j], i)) return -1;
    }
    size_t remaining[MAX_N], sample[MAX_Q];
    for (size_t i = 0; i < n; ++i) remaining[i] = i;
    for (size_t i = 0; i < q; ++i) {
        if (draws[i] < 0 || (uint64_t)draws[i] >= n - i) return -1;
        size_t selected = i + (size_t)draws[i];
        size_t temp = remaining[i]; remaining[i] = remaining[selected]; remaining[selected] = temp;
        sample[i] = remaining[i];
    }

    uint8_t adjacent[MAX_Q][MAX_Q] = {{0}};
    for (size_t i = 0; i < q; ++i)
        for (size_t j = i + 1; j < q; ++j)
            adjacent[i][j] = adjacent[j][i] = (uint8_t)has_edge(rows[sample[i]], sample[j]);
    int color[MAX_Q];
    for (size_t i = 0; i < q; ++i) color[i] = -1;
    int accepted = 1;
    for (size_t start = 0; start < q; ++start) {
        if (color[start] != -1) continue;
        size_t queue[MAX_Q], head = 0, tail = 0;
        queue[tail++] = start; color[start] = 0;
        while (head < tail) {
            size_t vertex = queue[head++];
            for (size_t neighbor = 0; neighbor < q; ++neighbor) {
                if (!adjacent[vertex][neighbor]) continue;
                if (color[neighbor] == -1) { color[neighbor] = color[vertex] ^ 1; queue[tail++] = neighbor; }
                else if (color[neighbor] == color[vertex]) accepted = 0;
            }
        }
    }
    if (!output || capacity < 16) return -2;
    uint8_t staged[16];
    put_i64(staged, 0, accepted);
    put_i64(staged, 8, (int64_t)(q * (q - 1) / 2));
    for (size_t i = 0; i < 16; ++i) output[i] = staged[i];
    return 16;
}
