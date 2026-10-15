#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 64
#define MAX_EDGE_COUNT 2047
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGE_COUNT)

static void visit_vertex(const uint64_t *adjacency, uint64_t *bridges, size_t vertex_count,
                         size_t vertex, int64_t *discovery, int64_t *low,
                         int64_t *parent, size_t *time)
{
    discovery[vertex] = low[vertex] = (int64_t)(*time);
    ++*time;
    for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) == 0) continue;
        if (discovery[neighbor] == -1) {
            parent[neighbor] = (int64_t)vertex;
            visit_vertex(adjacency, bridges, vertex_count, neighbor, discovery, low, parent, time);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
            if (low[neighbor] > discovery[vertex]) {
                bridges[vertex] |= UINT64_C(1) << neighbor;
                bridges[neighbor] |= UINT64_C(1) << vertex;
            }
        } else if ((int64_t)neighbor != parent[vertex] && discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
}

int64_t bridges(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT)
        return -1;
    const size_t vertex_count = (size_t)input[0];
    const size_t edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;

    uint64_t adjacency[MAX_VERTEX_COUNT] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_value = input[2 + 2 * edge];
        const int64_t right_value = input[3 + 2 * edge];
        if (left_value < 0 || right_value < 0 || left_value >= (int64_t)vertex_count ||
            right_value >= (int64_t)vertex_count) return -1;
        const size_t left = (size_t)left_value, right = (size_t)right_value;
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    int64_t discovery[MAX_VERTEX_COUNT], low[MAX_VERTEX_COUNT], parent[MAX_VERTEX_COUNT];
    uint64_t bridge_mask[MAX_VERTEX_COUNT] = {0};
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        discovery[vertex] = -1;
        low[vertex] = 0;
        parent[vertex] = -1;
    }
    size_t time = 0;
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (discovery[vertex] == -1)
            visit_vertex(adjacency, bridge_mask, vertex_count, vertex, discovery, low, parent, &time);

    size_t bridge_count = 0;
    for (size_t left = 0; left < vertex_count; ++left)
        for (size_t right = left + 1; right < vertex_count; ++right)
            if ((bridge_mask[left] & (UINT64_C(1) << right)) != 0) ++bridge_count;
    const size_t output_length = 2 * bridge_count;
    if (output_capacity < output_length || (output_length != 0 && output == NULL)) return -2;
    size_t position = 0;
    for (size_t left = 0; left < vertex_count; ++left)
        for (size_t right = left + 1; right < vertex_count; ++right)
            if ((bridge_mask[left] & (UINT64_C(1) << right)) != 0) {
                output[position++] = (uint8_t)left;
                output[position++] = (uint8_t)right;
            }
    return (int64_t)output_length;
}
