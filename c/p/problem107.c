#include <stddef.h>
#include <stdint.h>

enum { MAX_VERTICES = 40, MAX_EDGE_WEIGHT = 999 };

static int64_t edge_weight(const int64_t *input, size_t left, size_t right)
{
    if (left == right) return -1;
    const size_t row = left > right ? left : right;
    const size_t column = left > right ? right : left;
    return input[1 + row * (row - 1) / 2 + column];
}

int64_t problem107(const int64_t *input, size_t length)
{
    if (input == NULL || length < 1) return -1;
    const int64_t vertex_count_value = input[0];
    if (vertex_count_value < 1 || vertex_count_value > MAX_VERTICES) return -1;
    const size_t vertex_count = (size_t)vertex_count_value;
    if (length != 1 + vertex_count * (vertex_count - 1) / 2) return -1;

    int64_t total_weight = 0;
    for (size_t index = 1; index < length; ++index) {
        if (input[index] < -1 || input[index] > MAX_EDGE_WEIGHT) return -1;
        if (input[index] >= 0) total_weight += input[index];
    }

    uint8_t selected[MAX_VERTICES] = {0};
    int64_t best_weight[MAX_VERTICES];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) best_weight[vertex] = MAX_EDGE_WEIGHT + 1;
    best_weight[0] = 0;
    int64_t tree_weight = 0;
    for (size_t iteration = 0; iteration < vertex_count; ++iteration) {
        size_t next_vertex = vertex_count;
        int64_t next_weight = MAX_EDGE_WEIGHT + 1;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (!selected[vertex] && best_weight[vertex] < next_weight) {
                next_vertex = vertex;
                next_weight = best_weight[vertex];
            }
        }
        if (next_vertex == vertex_count) return -1;
        selected[next_vertex] = 1;
        tree_weight += next_weight;
        for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
            if (selected[vertex]) continue;
            const int64_t weight = edge_weight(input, next_vertex, vertex);
            if (weight >= 0 && weight < best_weight[vertex]) best_weight[vertex] = weight;
        }
    }
    return total_weight - tree_weight;
}
