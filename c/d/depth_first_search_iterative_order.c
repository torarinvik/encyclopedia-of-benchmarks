#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 10
#define MAX_EDGES 64
#define MAX_DEGREE (2 * MAX_EDGES)

static void put_i64(uint8_t *out, size_t word, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) out[word * 8 + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t depth_first_search_iterative_order(const int64_t *input, size_t length,
    uint8_t *output, size_t capacity) {
    if (!input || length < 3) return -1;
    int64_t node_count_value = input[0], edge_count_value = input[1];
    if (node_count_value < 1 || node_count_value > MAX_VERTICES ||
        edge_count_value < 0 || edge_count_value > MAX_EDGES ||
        length != 3 + 2 * (size_t)edge_count_value) return -1;
    int node_count = (int)node_count_value;
    int adjacency[MAX_VERTICES + 1][MAX_DEGREE] = {{0}};
    int degree[MAX_VERTICES + 1] = {0};
    for (int edge = 0; edge < (int)edge_count_value; ++edge) {
        int64_t left_value = input[2 + 2 * edge], right_value = input[3 + 2 * edge];
        if (left_value < 1 || left_value > node_count || right_value < 1 || right_value > node_count) return -1;
        int left = (int)left_value, right = (int)right_value;
        adjacency[left][degree[left]++] = right;
        adjacency[right][degree[right]++] = left;
    }
    int64_t start_value = input[length - 1];
    if (start_value < 1 || start_value > node_count) return -1;
    int start = (int)start_value;
    int stack[MAX_VERTICES], order[MAX_VERTICES], order_count = 0, stack_size = 0;
    uint8_t visited[MAX_VERTICES + 1] = {0};
    visited[start] = 1;
    stack[stack_size++] = start;
    while (stack_size > 0) {
        int vertex = stack[--stack_size];
        order[order_count++] = vertex;
        for (int edge = 0; edge < degree[vertex]; ++edge) {
            int neighbor = adjacency[vertex][edge];
            if (!visited[neighbor]) {
                visited[neighbor] = 1;
                stack[stack_size++] = neighbor;
            }
        }
    }
    size_t words = (size_t)order_count + 1;
    if (!output || capacity < words * 8) return -2;
    put_i64(output, 0, order_count);
    for (int index = 0; index < order_count; ++index) put_i64(output, (size_t)index + 1, order[index]);
    return (int64_t)(words * 8);
}
