#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 64
#define MAX_EDGES 94
#define MAX_INPUT_LENGTH (4 + MAX_NODES + 2 * MAX_EDGES)
#define MAX_OUTPUT_BYTES 128

int64_t depth_first_search_target_route(const int64_t *values, size_t length,
                                        uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 5 || length > MAX_INPUT_LENGTH) return -2;
    if (values[0] < 1 || values[0] > MAX_NODES) return -2;
    if (values[1] < 0 || values[1] > 255 || values[2] < 0 || values[2] > 255) return -2;
    const size_t node_count = (size_t)values[0];
    const int64_t start_label = values[1];
    const int64_t target_label = values[2];
    const size_t edge_count_position = 3 + node_count;
    if (edge_count_position >= length) return -2;

    int64_t labels[MAX_NODES];
    size_t start_index = node_count;
    for (size_t index = 0; index < node_count; ++index) {
        const int64_t label = values[3 + index];
        if (label < 0 || label > 255) return -2;
        for (size_t prior = 0; prior < index; ++prior) {
            if (labels[prior] == label) return -2;
        }
        labels[index] = label;
        if (label == start_label) start_index = index;
    }
    if (start_index == node_count) return -2;

    const int64_t edge_count_value = values[edge_count_position];
    if (edge_count_value < 0 || edge_count_value > MAX_EDGES) return -2;
    const size_t edge_count = (size_t)edge_count_value;
    if (length != edge_count_position + 1 + 2 * edge_count) return -2;

    uint64_t adjacency[MAX_NODES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left_label = values[edge_count_position + 1 + 2 * edge];
        const int64_t right_label = values[edge_count_position + 2 + 2 * edge];
        size_t left = node_count;
        size_t right = node_count;
        for (size_t index = 0; index < node_count; ++index) {
            if (labels[index] == left_label) left = index;
            if (labels[index] == right_label) right = index;
        }
        if (left == node_count || right == node_count) return -2;
        adjacency[left] |= UINT64_C(1) << right;
        adjacency[right] |= UINT64_C(1) << left;
    }

    size_t stack[MAX_NODES];
    size_t stack_length = 1;
    stack[0] = start_index;
    uint8_t route[MAX_OUTPUT_BYTES];
    size_t route_length = 0;
    while (stack_length != 0) {
        const size_t current = stack[--stack_length];
        if (route_length == MAX_OUTPUT_BYTES) return -2;
        route[route_length++] = (uint8_t)labels[current];
        for (size_t neighbor = 0; neighbor < node_count; ++neighbor) {
            const uint64_t bit = UINT64_C(1) << neighbor;
            if ((adjacency[current] & bit) != 0) {
                size_t pending = 0;
                while (pending < stack_length && stack[pending] != neighbor) ++pending;
                if (pending == stack_length) stack[stack_length++] = neighbor;
            }
            adjacency[current] &= ~bit;
            adjacency[neighbor] &= ~(UINT64_C(1) << current);
        }
        if (labels[current] == target_label) {
            if (output_capacity < route_length || (route_length != 0 && output == NULL)) return -2;
            for (size_t index = 0; index < route_length; ++index) output[index] = route[index];
            return (int64_t)route_length;
        }
    }
    return 0;
}
