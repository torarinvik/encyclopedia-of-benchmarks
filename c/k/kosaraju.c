#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 40
#define MAX_EDGE_COUNT 2047
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGE_COUNT)

static void fill_order(const uint64_t *adjacency, size_t vertex_count, size_t vertex,
                       bool *visited, size_t *order, size_t *order_length)
{
    visited[vertex] = true;
    for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor)
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor])
            fill_order(adjacency, vertex_count, neighbor, visited, order, order_length);
    order[(*order_length)++] = vertex;
}

static void collect_component(const uint64_t *transpose, size_t vertex_count, size_t vertex,
                              bool *visited, int64_t *component_id, int64_t id)
{
    visited[vertex] = true;
    component_id[vertex] = id;
    for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor)
        if ((transpose[vertex] & (UINT64_C(1) << neighbor)) != 0 && !visited[neighbor])
            collect_component(transpose, vertex_count, neighbor, visited, component_id, id);
}

int64_t kosaraju(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT)
        return -1;
    const size_t vertex_count = (size_t)input[0], edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;
    uint64_t adjacency[MAX_VERTEX_COUNT] = {0}, transpose[MAX_VERTEX_COUNT] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || from_value >= (int64_t)vertex_count ||
            to_value >= (int64_t)vertex_count) return -1;
        const size_t from = (size_t)from_value, to = (size_t)to_value;
        adjacency[from] |= UINT64_C(1) << to;
        transpose[to] |= UINT64_C(1) << from;
    }
    bool visited[MAX_VERTEX_COUNT] = {false};
    size_t order[MAX_VERTEX_COUNT], order_length = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (!visited[vertex]) fill_order(adjacency, vertex_count, vertex, visited, order, &order_length);
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) visited[vertex] = false;
    int64_t component_id[MAX_VERTEX_COUNT];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) component_id[vertex] = -1;
    size_t component_count = 0;
    while (order_length > 0) {
        const size_t vertex = order[--order_length];
        if (!visited[vertex])
            collect_component(transpose, vertex_count, vertex, visited, component_id, (int64_t)component_count++);
    }
    const size_t output_length = 1 + vertex_count + component_count;
    if (output_capacity < output_length || output == NULL) return -2;
    output[0] = (uint8_t)component_count;
    size_t position = 1;
    for (size_t first = 0; first < vertex_count; ++first) {
        const int64_t id = component_id[first];
        bool already_emitted = false;
        for (size_t earlier = 0; earlier < first; ++earlier)
            if (component_id[earlier] == id) already_emitted = true;
        if (already_emitted) continue;
        size_t component_size = 0;
        for (size_t vertex = first; vertex < vertex_count; ++vertex)
            if (component_id[vertex] == id) ++component_size;
        output[position++] = (uint8_t)component_size;
        for (size_t vertex = first; vertex < vertex_count; ++vertex)
            if (component_id[vertex] == id) output[position++] = (uint8_t)vertex;
    }
    return (int64_t)output_length;
}
