#include <stddef.h>
#include <stdint.h>

#define MAX_NODES 10
#define MAX_EDGES 100
#define MAX_SIGNATURE_LENGTH 4
#define MAX_LABEL 7

static int search_leg(const int64_t *values, size_t edge_count, size_t labels_start,
                      size_t signature_start, size_t signature_length, size_t node,
                      size_t signature_index, uint16_t *visited) {
    const uint16_t bit = (uint16_t)(1u << node);
    if ((*visited & bit) != 0) return 0;
    *visited |= bit;

    const int64_t target_label = values[signature_start + signature_index];
    for (size_t edge = 0; edge < edge_count; ++edge) {
        if ((size_t)values[3 + 2 * edge] != node) continue;
        const size_t target = (size_t)values[4 + 2 * edge];
        if (values[labels_start + target] != target_label) continue;
        if (signature_index + 1 == signature_length) return 1;
        uint16_t next_visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start,
                       signature_length, target, signature_index + 1, &next_visited))
            return 1;
    }

    for (size_t edge = 0; edge < edge_count; ++edge) {
        if ((size_t)values[3 + 2 * edge] != node) continue;
        const size_t target = (size_t)values[4 + 2 * edge];
        if (search_leg(values, edge_count, labels_start, signature_start,
                       signature_length, target, signature_index, visited))
            return 1;
    }
    return 0;
}

int64_t doe_pathfinder_signature_search(const int64_t *values, size_t length) {
    if (values == NULL || length < 3 || values[0] < 1 || values[0] > MAX_NODES ||
        values[1] < 0 || values[1] > MAX_EDGES || values[2] < 2 ||
        values[2] > MAX_SIGNATURE_LENGTH) return -2;
    const size_t node_count = (size_t)values[0];
    const size_t edge_count = (size_t)values[1];
    const size_t signature_length = (size_t)values[2];
    if (edge_count > node_count * node_count ||
        length != 3 + 2 * edge_count + node_count + signature_length) return -2;

    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t from = values[3 + 2 * edge];
        const int64_t to = values[4 + 2 * edge];
        if (from < 0 || from >= (int64_t)node_count || to < 0 || to >= (int64_t)node_count)
            return -2;
        for (size_t previous = 0; previous < edge; ++previous)
            if (values[3 + 2 * previous] == from && values[4 + 2 * previous] == to)
                return -2;
    }
    const size_t labels_start = 3 + 2 * edge_count;
    const size_t signature_start = labels_start + node_count;
    for (size_t node = 0; node < node_count; ++node)
        if (values[labels_start + node] < -1 || values[labels_start + node] > MAX_LABEL)
            return -2;
    for (size_t index = 0; index < signature_length; ++index)
        if (values[signature_start + index] < 0 || values[signature_start + index] > MAX_LABEL)
            return -2;

    const int64_t first_label = values[signature_start];
    for (size_t node = 0; node < node_count; ++node) {
        if (values[labels_start + node] != first_label) continue;
        uint16_t visited = 0;
        if (search_leg(values, edge_count, labels_start, signature_start,
                       signature_length, node, 1, &visited)) return 1;
    }
    return 0;
}
