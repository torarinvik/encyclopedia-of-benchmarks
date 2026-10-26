#include <stddef.h>
#include <stdint.h>

#define MAX_N 16
#define MAX_M 120
#define MAX_INPUT (3 + 2 * MAX_M)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t lex_bfs(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 3 || length > MAX_INPUT) return -1;
    const int64_t n64 = input[0], m64 = input[1], start64 = input[2];
    if (n64 < 1 || n64 > MAX_N || m64 < 0 || m64 > MAX_M ||
        start64 < 0 || start64 >= n64 || length != 3 + 2 * (size_t)m64) return -1;
    const size_t n = (size_t)n64, m = (size_t)m64, start = (size_t)start64;
    int adjacency[MAX_N][MAX_N] = {{0}};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t u64 = input[3 + 2 * edge], v64 = input[4 + 2 * edge];
        if (u64 < 0 || v64 <= u64 || v64 >= n64) return -1;
        const size_t u = (size_t)u64, v = (size_t)v64;
        if (adjacency[u][v]) return -1;
        adjacency[u][v] = adjacency[v][u] = 1;
    }
    const size_t output_bytes = 8 * n;
    if (output == NULL || capacity < output_bytes) return -2;
    int64_t labels[MAX_N][MAX_N] = {{0}}, order[MAX_N] = {0};
    size_t label_len[MAX_N] = {0};
    int selected[MAX_N] = {0};
    size_t current = start;
    for (size_t step = 0; step < n; ++step) {
        if (step > 0) {
            int have_best = 0;
            for (size_t vertex = 0; vertex < n; ++vertex) {
                if (selected[vertex]) continue;
                if (!have_best) { current = vertex; have_best = 1; continue; }
                size_t position = 0;
                int decided = 0;
                const size_t shared = label_len[vertex] < label_len[current]
                    ? label_len[vertex] : label_len[current];
                while (position < shared) {
                    if (labels[vertex][position] != labels[current][position]) {
                        if (labels[vertex][position] > labels[current][position]) current = vertex;
                        decided = 1;
                        break;
                    }
                    ++position;
                }
                if (!decided && (label_len[vertex] > label_len[current] ||
                    (label_len[vertex] == label_len[current] && vertex < current))) current = vertex;
            }
        }
        selected[current] = 1;
        order[step] = (int64_t)current;
        for (size_t neighbor = 0; neighbor < n; ++neighbor) {
            if (!adjacency[current][neighbor] || selected[neighbor]) continue;
            for (size_t position = label_len[neighbor]; position > 0; --position)
                labels[neighbor][position] = labels[neighbor][position - 1];
            labels[neighbor][0] = (int64_t)step;
            ++label_len[neighbor];
        }
    }
    for (size_t index = 0; index < n; ++index) store_i64_le(output, 8 * index, order[index]);
    return (int64_t)output_bytes;
}
