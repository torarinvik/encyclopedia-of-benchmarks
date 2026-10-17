#include <stdint.h>
#include <stddef.h>

#define MAX_VERTICES 14
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VERTICES + 3)

static int find_root(int parent[MAX_VERTICES], int vertex) {
    while (parent[vertex] != vertex) {
        parent[vertex] = parent[parent[vertex]];
        vertex = parent[vertex];
    }
    return vertex;
}

int64_t mcoloring(const int64_t *input, size_t length) {
    if (input == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    int64_t n_value = input[0], colors_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || colors_value < 1 || colors_value > MAX_VERTICES) return -1;
    int n = (int)n_value;
    if (length != (size_t)n + 2) return -1;

    uint32_t masks[MAX_VERTICES] = {0};
    uint32_t valid_mask = n == 0 ? 0u : (1u << n) - 1u;
    int parent[MAX_VERTICES];
    for (int vertex = 0; vertex < n; ++vertex) {
        int64_t raw = input[vertex + 2];
        if (raw < 0 || (uint64_t)raw > valid_mask) return -1;
        masks[vertex] = (uint32_t)raw;
        if (masks[vertex] & (1u << vertex)) return -1;
        parent[vertex] = vertex;
    }
    for (int vertex = 0; vertex < n; ++vertex) {
        for (int neighbor = vertex + 1; neighbor < n; ++neighbor) {
            int has_edge = (masks[vertex] & (1u << neighbor)) != 0;
            if (has_edge != ((masks[neighbor] & (1u << vertex)) != 0)) return -1;
            if (has_edge) {
                int root_a = find_root(parent, vertex), root_b = find_root(parent, neighbor);
                if (root_a == root_b) return -1;
                parent[root_a] = root_b;
            }
        }
    }

    int colors[MAX_VERTICES], visited[MAX_VERTICES] = {0}, queue[MAX_VERTICES];
    for (int i = 0; i < n; ++i) colors[i] = 1;
    int maximum_color = 1;
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int head = 0, tail = 0;
        visited[start] = 1;
        queue[tail++] = start;
        while (head < tail) {
            int vertex = queue[head++];
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if ((masks[vertex] & (1u << neighbor)) == 0) continue;
                if (colors[vertex] == colors[neighbor]) ++colors[neighbor];
                if (colors[vertex] > maximum_color) maximum_color = colors[vertex];
                if (colors[neighbor] > maximum_color) maximum_color = colors[neighbor];
                if (maximum_color > colors_value) return 0;
                if (!visited[neighbor]) {
                    visited[neighbor] = 1;
                    queue[tail++] = neighbor;
                }
            }
        }
    }
    return 1;
}
