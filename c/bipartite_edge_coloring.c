#include <stddef.h>
#include <stdint.h>

enum { MAX_SIDE_VERTICES = 5, MAX_EDGES = 10, MAX_INPUT_LENGTH = 23, MAX_OUTPUT_BYTES = 88 };

static int augment_matching(size_t left, size_t side,
                            const int64_t multiplicity[MAX_SIDE_VERTICES][MAX_SIDE_VERTICES],
                            uint8_t seen[MAX_SIDE_VERTICES], int match_right[MAX_SIDE_VERTICES]) {
    for (size_t right = 0; right < side; ++right) {
        if (multiplicity[left][right] == 0 || seen[right]) continue;
        seen[right] = 1;
        if (match_right[right] < 0 || augment_matching((size_t)match_right[right], side,
                                                       multiplicity, seen, match_right)) {
            match_right[right] = (int)left;
            return 1;
        }
    }
    return 0;
}

int64_t bipartite_edge_coloring(const int64_t *values, size_t length,
                                uint8_t *output, size_t output_capacity) {
    if (values == NULL || length < 3 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t left_value = values[0];
    const int64_t right_value = values[1];
    const int64_t edge_value = values[2];
    if (left_value < 1 || left_value > MAX_SIDE_VERTICES ||
        right_value < 1 || right_value > MAX_SIDE_VERTICES ||
        edge_value < 1 || edge_value > MAX_EDGES) return -1;
    const size_t left_count = (size_t)left_value;
    const size_t right_count = (size_t)right_value;
    const size_t edge_count = (size_t)edge_value;
    if (length != 3 + 2 * edge_count) return -1;

    int64_t multiplicity[MAX_SIDE_VERTICES][MAX_SIDE_VERTICES] = {{0}};
    int64_t original_remaining[MAX_SIDE_VERTICES][MAX_SIDE_VERTICES] = {{0}};
    size_t left_degree[MAX_SIDE_VERTICES] = {0};
    size_t right_degree[MAX_SIDE_VERTICES] = {0};
    for (size_t edge = 0; edge < edge_count; ++edge) {
        const int64_t left = values[3 + 2 * edge];
        const int64_t right = values[4 + 2 * edge];
        if (left < 0 || left >= left_value || right < 0 || right >= right_value) return -1;
        ++multiplicity[(size_t)left][(size_t)right];
        ++original_remaining[(size_t)left][(size_t)right];
        ++left_degree[(size_t)left];
        ++right_degree[(size_t)right];
    }

    const size_t side = left_count > right_count ? left_count : right_count;
    size_t maximum_degree = 0;
    for (size_t vertex = 0; vertex < side; ++vertex) {
        if (left_degree[vertex] > maximum_degree) maximum_degree = left_degree[vertex];
        if (right_degree[vertex] > maximum_degree) maximum_degree = right_degree[vertex];
    }
    for (;;) {
        size_t left = 0;
        while (left < side && left_degree[left] == maximum_degree) ++left;
        if (left == side) break;
        size_t right = 0;
        while (right < side && right_degree[right] == maximum_degree) ++right;
        if (right == side) return -1;
        ++multiplicity[left][right];
        ++left_degree[left];
        ++right_degree[right];
    }

    int64_t colors[MAX_EDGES];
    for (size_t edge = 0; edge < edge_count; ++edge) colors[edge] = -1;
    for (size_t color = 0; color < maximum_degree; ++color) {
        int match_right[MAX_SIDE_VERTICES];
        for (size_t right = 0; right < side; ++right) match_right[right] = -1;
        for (size_t left = 0; left < side; ++left) {
            uint8_t seen[MAX_SIDE_VERTICES] = {0};
            if (!augment_matching(left, side, multiplicity, seen, match_right)) return -1;
        }
        for (size_t right = 0; right < side; ++right) {
            const size_t left = (size_t)match_right[right];
            if (original_remaining[left][right] > 0) {
                size_t edge = 0;
                while (edge < edge_count &&
                       (colors[edge] >= 0 || values[3 + 2 * edge] != (int64_t)left ||
                        values[4 + 2 * edge] != (int64_t)right)) ++edge;
                if (edge == edge_count) return -1;
                colors[edge] = (int64_t)color;
                --original_remaining[left][right];
            }
            --multiplicity[left][right];
        }
    }

    const size_t output_elements = edge_count + 1;
    const size_t bytes = 8 * output_elements;
    if (output == NULL || output_capacity < bytes) return -2;
    uint8_t staged[MAX_OUTPUT_BYTES] = {0};
    const uint64_t color_count = (uint64_t)maximum_degree;
    for (size_t byte = 0; byte < 8; ++byte) staged[byte] = (uint8_t)(color_count >> (8 * byte));
    for (size_t edge = 0; edge < edge_count; ++edge)
        for (size_t byte = 0; byte < 8; ++byte)
            staged[8 * (edge + 1) + byte] = (uint8_t)((uint64_t)colors[edge] >> (8 * byte));
    for (size_t byte = 0; byte < bytes; ++byte) output[byte] = staged[byte];
    return (int64_t)bytes;
}
