#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_EDGES 256
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGES)
#define MAX_CELLS (MAX_VERTICES * MAX_VERTICES)

int64_t bipartite_graph_dfs(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES || input[1] < 0 || input[1] > MAX_EDGES) return -1;
    const size_t n = (size_t)input[0], m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;

    uint8_t adjacency[MAX_CELLS] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        const int64_t from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || from_value >= (int64_t)n || to_value < 0 || to_value >= (int64_t)n) return -1;
        const size_t from = (size_t)from_value, to = (size_t)to_value;
        adjacency[from * n + to] = 1;
        adjacency[to * n + from] = 1;
    }

    int8_t color[MAX_VERTICES];
    size_t stack[MAX_VERTICES];
    for (size_t i = 0; i < n; ++i) color[i] = -1;
    for (size_t start = 0; start < n; ++start) {
        if (color[start] != -1) continue;
        size_t top = 0;
        stack[top++] = start;
        color[start] = 0;
        while (top > 0) {
            const size_t node = stack[--top];
            for (size_t neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[node * n + neighbor] == 0) continue;
                if (color[neighbor] == -1) {
                    color[neighbor] = (int8_t)(1 - color[node]);
                    stack[top++] = neighbor;
                } else if (color[neighbor] == color[node]) return 0;
            }
        }
    }
    return 1;
}
