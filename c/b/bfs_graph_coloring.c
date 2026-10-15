/* Adapt Go ColorUsingBFS on dense-label star forests. */
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#define MAX_VERTICES 64
#define MAX_EDGES ((MAX_VERTICES * (MAX_VERTICES - 1)) / 2)
#define MAX_OUTPUT_VALUES (MAX_VERTICES + 2)

static void put_i64(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t bfs_graph_coloring(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return -1;
    int64_t n_value = input[0], m_value = input[1];
    if (n_value < 0 || n_value > MAX_VERTICES || m_value < 0 || m_value > MAX_EDGES
            || length != 2 + 2 * (size_t)m_value) return -1;
    const int n = (int)n_value, m = (int)m_value;
    bool adjacency[MAX_VERTICES * MAX_VERTICES] = {false};
    int degree[MAX_VERTICES] = {0};
    for (int edge = 0; edge < m; ++edge) {
        int64_t u_value = input[2 + 2 * edge], v_value = input[3 + 2 * edge];
        if (u_value < 0 || u_value >= n || v_value < 0 || v_value >= n || u_value == v_value) return -1;
        int u = (int)u_value, v = (int)v_value;
        size_t uv = (size_t)u * MAX_VERTICES + (size_t)v;
        size_t vu = (size_t)v * MAX_VERTICES + (size_t)u;
        if (adjacency[uv]) return -1;
        adjacency[uv] = adjacency[vu] = true;
        ++degree[u]; ++degree[v];
    }
    bool visited[MAX_VERTICES] = {false};
    int queue[MAX_VERTICES];
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int head = 0, tail = 0, high_degree = 0;
        visited[start] = true; queue[tail++] = start;
        while (head < tail) {
            int vertex = queue[head++];
            if (degree[vertex] > 1) ++high_degree;
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (adjacency[(size_t)vertex * MAX_VERTICES + (size_t)neighbor] && !visited[neighbor]) {
                    visited[neighbor] = true; queue[tail++] = neighbor;
                }
            }
        }
        if (high_degree > 1) return -1;
    }
    int64_t colors[MAX_VERTICES];
    for (int i = 0; i < n; ++i) colors[i] = 1;
    for (int i = 0; i < MAX_VERTICES; ++i) visited[i] = false;
    for (int start = 0; start < n; ++start) {
        if (visited[start]) continue;
        int head = 0, tail = 0;
        visited[start] = true; queue[tail++] = start;
        while (head < tail) {
            int front = queue[head++];
            for (int neighbor = 0; neighbor < n; ++neighbor) {
                if (!adjacency[(size_t)front * MAX_VERTICES + (size_t)neighbor]) continue;
                if (colors[neighbor] == colors[front]) ++colors[neighbor];
                if (!visited[neighbor]) { visited[neighbor] = true; queue[tail++] = neighbor; }
            }
        }
    }
    int64_t colors_used = 0;
    for (int i = 0; i < n; ++i) if (colors[i] > colors_used) colors_used = colors[i];
    int64_t packed[MAX_OUTPUT_VALUES];
    packed[0] = n;
    for (int i = 0; i < n; ++i) packed[i + 1] = colors[i];
    packed[n + 1] = colors_used;
    size_t used = (size_t)n + 2, required = used * 8;
    if (output == NULL || capacity < required) return -2;
    for (size_t i = 0; i < used; ++i) put_i64(output, i * 8, packed[i]);
    return (int64_t)required;
}
