/* Directed one-target Bellman-Ford with Go map last-write edge normalization. */
#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 64
#define MAX_INPUT_EDGES 256
#define MAX_NORMALIZED_EDGES 128
#define MAX_WEIGHT 1000
#define RECORD_BYTES 24

static int64_t write_record(uint8_t *output, size_t capacity, int64_t status,
                            int64_t reachable, int64_t distance) {
    if (output == NULL || capacity < RECORD_BYTES) return -2;
    const int64_t record[3] = {status, reachable, distance};
    for (size_t field = 0; field < 3; ++field) {
        const uint64_t bits = (uint64_t)record[field];
        for (size_t byte = 0; byte < 8; ++byte)
            output[field * 8 + byte] = (uint8_t)(bits >> (byte * 8));
    }
    return RECORD_BYTES;
}

int64_t bellman_ford_pair(const int64_t *input, size_t length,
                          uint8_t *output, size_t capacity) {
    if (input == NULL || length < 4) return -1;
    const int64_t vertices_value = input[0];
    const int64_t input_edges_value = input[1];
    const int64_t source_value = input[2];
    const int64_t target_value = input[3];
    if (vertices_value < 1 || vertices_value > MAX_VERTICES ||
        input_edges_value < 0 || input_edges_value > MAX_INPUT_EDGES) return -1;
    const size_t vertices = (size_t)vertices_value;
    const size_t input_edges = (size_t)input_edges_value;
    if (source_value < 0 || source_value >= vertices_value ||
        target_value < 0 || target_value >= vertices_value || length != 4 + 3 * input_edges) return -1;

    int64_t matrix_weights[MAX_VERTICES * MAX_VERTICES] = {0};
    uint8_t matrix_present[MAX_VERTICES * MAX_VERTICES] = {0};
    size_t normalized_count = 0;
    for (size_t edge = 0; edge < input_edges; ++edge) {
        const int64_t from_value = input[4 + 3 * edge];
        const int64_t to_value = input[5 + 3 * edge];
        const int64_t weight = input[6 + 3 * edge];
        if (from_value < 0 || from_value >= vertices_value || to_value < 0 || to_value >= vertices_value ||
            weight < -MAX_WEIGHT || weight > MAX_WEIGHT) return -1;
        const size_t key = (size_t)from_value * vertices + (size_t)to_value;
        if (!matrix_present[key]) {
            matrix_present[key] = 1;
            if (++normalized_count > MAX_NORMALIZED_EDGES) return -1;
        }
        matrix_weights[key] = weight;
    }

    size_t from[MAX_NORMALIZED_EDGES], to[MAX_NORMALIZED_EDGES];
    int64_t weight[MAX_NORMALIZED_EDGES];
    size_t edge_count = 0;
    for (size_t origin = 0; origin < vertices; ++origin) {
        for (size_t destination = 0; destination < vertices; ++destination) {
            const size_t key = origin * vertices + destination;
            if (!matrix_present[key]) continue;
            from[edge_count] = origin;
            to[edge_count] = destination;
            weight[edge_count] = matrix_weights[key];
            ++edge_count;
        }
    }

    const size_t source = (size_t)source_value;
    const size_t target = (size_t)target_value;
    int64_t distance[MAX_VERTICES] = {0};
    uint8_t reachable[MAX_VERTICES] = {0};
    reachable[source] = 1;
    for (size_t round = 0; round < vertices; ++round) {
        int changed = 0;
        for (size_t edge = 0; edge < edge_count; ++edge) {
            if (!reachable[from[edge]]) continue;
            const int64_t candidate = distance[from[edge]] + weight[edge];
            if (!reachable[to[edge]] || candidate < distance[to[edge]]) {
                distance[to[edge]] = candidate;
                reachable[to[edge]] = 1;
                changed = 1;
            }
        }
        if (!changed) break;
    }
    for (size_t edge = 0; edge < edge_count; ++edge) {
        if (reachable[from[edge]] && distance[to[edge]] > distance[from[edge]] + weight[edge])
            return write_record(output, capacity, -1, 0, 0);
    }
    return write_record(output, capacity, 0, reachable[target], reachable[target] ? distance[target] : 0);
}
