#include <stddef.h>
#include <stdint.h>

#define MAX_VERTICES 16
#define MAX_NEIGHBORS 64
#define MAX_DEPTH 8
#define MAX_VALID_INPUT_LENGTH (4 + 2 * MAX_VERTICES + MAX_NEIGHBORS)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_VALID_INPUT_LENGTH + 1)
#define MAX_PATH_LENGTH (MAX_DEPTH + 1)
#define MAX_OUTPUT_VALUES (3 + MAX_PATH_LENGTH)
#define MAX_OUTPUT_BYTES (8 * MAX_OUTPUT_VALUES)

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t iddfs(const int64_t *values, size_t length, uint8_t *output,
              size_t output_capacity) {
    if (values == NULL || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const int64_t raw_start = values[0];
    const int64_t raw_target = values[1];
    const int64_t raw_depth = values[2];
    const int64_t raw_entries = values[3];
    if (raw_start < 1 || raw_start > MAX_VERTICES ||
        raw_target < 1 || raw_target > MAX_VERTICES ||
        raw_depth < 0 || raw_depth > MAX_DEPTH ||
        raw_entries < 0 || raw_entries > MAX_VERTICES) return -1;
    const int start = (int)raw_start;
    const int target = (int)raw_target;
    const size_t max_depth = (size_t)raw_depth;
    const size_t entry_count = (size_t)raw_entries;

    int32_t adjacency[MAX_VERTICES][MAX_NEIGHBORS];
    size_t degree_count[MAX_VERTICES] = {0};
    uint8_t named[MAX_VERTICES] = {0};
    size_t max_vertex = 0;
    size_t total_neighbors = 0;
    size_t cursor = 4;
    for (size_t entry = 0; entry < entry_count; ++entry) {
        if (cursor + 2 > length) return -1;
        const int64_t raw_vertex = values[cursor++];
        const int64_t raw_degree = values[cursor++];
        if (raw_vertex < 1 || raw_vertex > MAX_VERTICES ||
            raw_degree < 0 || raw_degree > MAX_NEIGHBORS) return -1;
        const size_t vertex = (size_t)raw_vertex;
        const size_t degree = (size_t)raw_degree;
        if (named[vertex - 1] || degree > length - cursor ||
            total_neighbors + degree > MAX_NEIGHBORS) return -1;
        named[vertex - 1] = 1;
        if (vertex > max_vertex) max_vertex = vertex;
        total_neighbors += degree;
        for (size_t neighbor_index = 0; neighbor_index < degree; ++neighbor_index) {
            const int64_t raw_neighbor = values[cursor++];
            if (raw_neighbor < -MAX_VERTICES || raw_neighbor > MAX_VERTICES) return -1;
            if (raw_neighbor > (int64_t)max_vertex) max_vertex = (size_t)raw_neighbor;
            if (raw_neighbor >= 1)
                adjacency[vertex - 1][degree_count[vertex - 1]++] = (int32_t)raw_neighbor;
        }
    }
    if (cursor != length) return -1;
    if (max_vertex != 0 && ((size_t)start > max_vertex || (size_t)target > max_vertex)) return -1;

    int64_t path[MAX_PATH_LENGTH] = {0};
    size_t next_neighbor[MAX_PATH_LENGTH] = {0};
    size_t path_length = 0;
    size_t found_depth = 0;
    int found = 0;
    if (max_vertex != 0) {
        for (size_t limit = 0; limit <= max_depth && !found; ++limit) {
            path_length = 1;
            path[0] = start;
            next_neighbor[0] = 0;
            if (start == target) {
                found = 1;
                found_depth = 0;
                break;
            }
            while (path_length != 0 && !found) {
                const size_t frame = path_length - 1;
                const int current = (int)path[frame];
                if (frame >= limit || next_neighbor[frame] >= degree_count[current - 1]) {
                    --path_length;
                    continue;
                }
                const int neighbor = adjacency[current - 1][next_neighbor[frame]++];
                size_t prior = 0;
                while (prior < path_length && path[prior] != neighbor) ++prior;
                if (prior != path_length) continue;
                path[path_length] = neighbor;
                ++path_length;
                if (neighbor == target) {
                    found = 1;
                    found_depth = path_length - 1;
                } else {
                    next_neighbor[path_length - 1] = 0;
                }
            }
        }
    }

    int64_t result[MAX_OUTPUT_VALUES] = {0};
    size_t result_count = 3;
    result[0] = found ? 1 : 0;
    result[1] = found ? (int64_t)found_depth : -1;
    result[2] = found ? (int64_t)path_length : 0;
    if (found) {
        result_count += path_length;
        for (size_t index = 0; index < path_length; ++index) result[3 + index] = path[index];
    }
    const size_t required = result_count * 8;
    if (output == NULL || output_capacity < required) return -2;
    for (size_t index = 0; index < result_count; ++index)
        store_i64_le(output, 8 * index, result[index]);
    return (int64_t)required;
}
