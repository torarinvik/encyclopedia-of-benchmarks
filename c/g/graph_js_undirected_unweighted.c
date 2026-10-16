#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 26
#define MAX_EDGES 256
#define MAX_DEGREE (2 * MAX_EDGES)
#define MAX_INPUT_LENGTH 541
#define MAX_OUTPUT_VALUES 645
#define MAX_QUEUE (1 + 2 * MAX_EDGES)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

static void dfs_visit(size_t vertex, const uint8_t adjacency[MAX_VERTICES][MAX_DEGREE],
                      const size_t degree[MAX_VERTICES], bool visited[MAX_VERTICES],
                      int64_t result[MAX_OUTPUT_VALUES], size_t *position, size_t *count) {
    if (visited[vertex]) return;
    visited[vertex] = true;
    result[(*position)++] = (int64_t)(97 + vertex);
    ++*count;
    for (size_t edge = 0; edge < degree[vertex]; ++edge) {
        dfs_visit(adjacency[vertex][edge], adjacency, degree, visited, result, position, count);
    }
}

int64_t graph_js_undirected_unweighted(const int64_t *input, size_t length,
                                      uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 1 || input[0] > MAX_VERTICES) return -1;
    const size_t vertex_count = (size_t)input[0];
    if (length < 1 + vertex_count + 2) return -1;

    uint8_t vertices[MAX_VERTICES];
    bool declared[MAX_VERTICES] = {false};
    for (size_t index = 0; index < vertex_count; ++index) {
        const int64_t value = input[1 + index];
        if (value < 'a' || value > 'z') return -1;
        const size_t vertex = (size_t)(value - 'a');
        if (declared[vertex]) return -1;
        declared[vertex] = true;
        vertices[index] = (uint8_t)vertex;
    }

    const size_t edge_count_offset = 1 + vertex_count;
    const int64_t raw_edge_count = input[edge_count_offset];
    if (raw_edge_count < 0 || raw_edge_count > MAX_EDGES) return -1;
    const size_t edge_count = (size_t)raw_edge_count;
    if (length != 1 + vertex_count + 1 + 2 * edge_count + 1) return -1;

    uint8_t adjacency[MAX_VERTICES][MAX_DEGREE] = {{0}};
    size_t degree[MAX_VERTICES] = {0};
    size_t position = edge_count_offset + 1;
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_value = input[position++];
        const int64_t right_value = input[position++];
        if (left_value < 'a' || left_value > 'z' || right_value < 'a' || right_value > 'z') return -1;
        const size_t left = (size_t)(left_value - 'a');
        const size_t right = (size_t)(right_value - 'a');
        if (declared[left] && declared[right]) {
            if (degree[left] >= MAX_DEGREE || degree[right] >= MAX_DEGREE) return -1;
            adjacency[left][degree[left]++] = (uint8_t)right;
            adjacency[right][degree[right]++] = (uint8_t)left;
        }
    }
    const int64_t start_value = input[position];
    if (start_value < 'a' || start_value > 'z') return -1;
    const size_t start = (size_t)(start_value - 'a');
    if (!declared[start]) return -1;

    int64_t result[MAX_OUTPUT_VALUES];
    size_t result_length = 0;
    result[result_length++] = (int64_t)vertex_count;
    for (size_t index = 0; index < vertex_count; ++index) {
        const size_t vertex = vertices[index];
        result[result_length++] = (int64_t)(97 + vertex);
        result[result_length++] = (int64_t)degree[vertex];
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            result[result_length++] = (int64_t)(97 + adjacency[vertex][edge]);
        }
    }

    bool visited[MAX_VERTICES] = {false};
    uint8_t queue[MAX_QUEUE], levels[MAX_QUEUE];
    size_t head = 0, tail = 0, bfs_count = 0;
    const size_t bfs_count_slot = result_length++;
    queue[tail] = (uint8_t)start;
    levels[tail++] = 0;
    while (head < tail) {
        const size_t vertex = queue[head];
        const size_t level = levels[head++];
        if (visited[vertex]) continue;
        visited[vertex] = true;
        result[result_length++] = (int64_t)(97 + vertex);
        result[result_length++] = (int64_t)level;
        ++bfs_count;
        for (size_t edge = 0; edge < degree[vertex]; ++edge) {
            queue[tail] = adjacency[vertex][edge];
            levels[tail++] = (uint8_t)(level + 1);
        }
    }
    result[bfs_count_slot] = (int64_t)bfs_count;

    for (size_t index = 0; index < MAX_VERTICES; ++index) visited[index] = false;
    const size_t dfs_count_slot = result_length++;
    size_t dfs_count = 0;
    dfs_visit(start, adjacency, degree, visited, result, &result_length, &dfs_count);
    result[dfs_count_slot] = (int64_t)dfs_count;

    const size_t output_bytes = result_length * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < result_length; ++index) store_i64_le(output, index * 8, result[index]);
    return (int64_t)output_bytes;
}
