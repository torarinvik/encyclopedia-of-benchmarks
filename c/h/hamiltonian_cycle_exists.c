#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 8
#define MAX_INPUT_LENGTH 58

static int has_cycle(size_t n, const uint8_t *graph, uint8_t *visited,
                     size_t current, size_t position) {
    if (position == n) return graph[current * MAX_VERTICES] != 0;
    for (size_t next = 0; next < n; ++next) {
        if (graph[current * MAX_VERTICES + next] && !visited[next]) {
            visited[next] = 1;
            if (has_cycle(n, graph, visited, next, position + 1)) return 1;
            visited[next] = 0;
        }
    }
    return 0;
}

int64_t hamiltonian_cycle_exists(const int64_t *input, size_t length) {
    if (!input || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 3 || input[0] > MAX_VERTICES || input[1] < 0) return -1;
    size_t n = (size_t)input[0];
    if (input[1] > (int64_t)(n * (n - 1) / 2)) return -1;
    size_t m = (size_t)input[1];
    if (length != 2 + 2 * m) return -1;
    uint8_t graph[MAX_VERTICES * MAX_VERTICES] = {0};
    for (size_t edge = 0; edge < m; ++edge) {
        int64_t u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || v_value < 0 || u_value >= (int64_t)n || v_value >= (int64_t)n || u_value == v_value) return -1;
        size_t u = (size_t)u_value, v = (size_t)v_value;
        if (graph[u * MAX_VERTICES + v]) return -1;
        graph[u * MAX_VERTICES + v] = graph[v * MAX_VERTICES + u] = 1;
    }
    uint8_t visited[MAX_VERTICES] = {0};
    visited[0] = 1;
    return has_cycle(n, graph, visited, 0, 1);
}
