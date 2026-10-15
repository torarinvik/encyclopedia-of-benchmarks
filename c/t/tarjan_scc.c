#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTEX_COUNT 40
#define MAX_EDGE_COUNT 2047
#define MAX_INPUT_LENGTH (2 + 2 * MAX_EDGE_COUNT)

static void visit_vertex(const uint64_t *adjacency, size_t vertex_count, size_t vertex,
                         bool *on_stack, size_t *stack, size_t *stack_length,
                         int64_t *discovery, int64_t *low, int64_t *component_id,
                         size_t *time, size_t *component_count)
{
    discovery[vertex] = low[vertex] = (int64_t)(*time)++;
    on_stack[vertex] = true;
    stack[(*stack_length)++] = vertex;
    for (size_t neighbor = 0; neighbor < vertex_count; ++neighbor) {
        if ((adjacency[vertex] & (UINT64_C(1) << neighbor)) == 0) continue;
        if (discovery[neighbor] == -1) {
            visit_vertex(adjacency, vertex_count, neighbor, on_stack, stack, stack_length,
                         discovery, low, component_id, time, component_count);
            if (low[neighbor] < low[vertex]) low[vertex] = low[neighbor];
        } else if (on_stack[neighbor] && discovery[neighbor] < low[vertex]) {
            low[vertex] = discovery[neighbor];
        }
    }
    if (low[vertex] == discovery[vertex]) {
        while (*stack_length > 0) {
            const size_t member = stack[--*stack_length];
            on_stack[member] = false;
            component_id[member] = (int64_t)*component_count;
            if (member == vertex) break;
        }
        ++*component_count;
    }
}

int64_t tarjan_scc(const int64_t *input, size_t length, uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_VERTEX_COUNT || input[1] < 0 || input[1] > MAX_EDGE_COUNT)
        return -1;
    const size_t vertex_count = (size_t)input[0], edge_count = (size_t)input[1];
    if (length != 2 + 2 * edge_count) return -1;
    uint64_t adjacency[MAX_VERTEX_COUNT] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t from_value = input[2 + 2 * edge], to_value = input[3 + 2 * edge];
        if (from_value < 0 || to_value < 0 || from_value >= (int64_t)vertex_count ||
            to_value >= (int64_t)vertex_count) return -1;
        const size_t from = (size_t)from_value, to = (size_t)to_value;
        adjacency[from] |= UINT64_C(1) << to;
    }
    bool on_stack[MAX_VERTEX_COUNT] = {false};
    size_t stack[MAX_VERTEX_COUNT], stack_length = 0, time = 0, component_count = 0;
    int64_t discovery[MAX_VERTEX_COUNT], low[MAX_VERTEX_COUNT], component_id[MAX_VERTEX_COUNT];
    for (size_t vertex = 0; vertex < vertex_count; ++vertex) {
        discovery[vertex] = -1;
        low[vertex] = 0;
        component_id[vertex] = -1;
    }
    for (size_t vertex = 0; vertex < vertex_count; ++vertex)
        if (discovery[vertex] == -1)
            visit_vertex(adjacency, vertex_count, vertex, on_stack, stack, &stack_length,
                         discovery, low, component_id, &time, &component_count);
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
