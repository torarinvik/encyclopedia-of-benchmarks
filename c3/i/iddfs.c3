module iddfs;

const usz MAX_VERTICES = 16;
const usz MAX_NEIGHBORS = 64;
const usz MAX_DEPTH = 8;
const usz MAX_VALID_INPUT_LENGTH = 4 + 2 * MAX_VERTICES + MAX_NEIGHBORS;
const usz MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1;
const usz MAX_PATH_LENGTH = MAX_DEPTH + 1;
const usz MAX_OUTPUT_VALUES = 3 + MAX_PATH_LENGTH;

fn void store_i64_le(long value, char* output, usz offset) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

fn long iddfs(long* values, usz length, char* output,
              usz output_capacity) @export("iddfs") {
    if (values == null || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    long raw_start = values[0];
    long raw_target = values[1];
    long raw_depth = values[2];
    long raw_entries = values[3];
    if (raw_start < 1 || raw_start > 16 || raw_target < 1 || raw_target > 16 ||
        raw_depth < 0 || raw_depth > 8 || raw_entries < 0 || raw_entries > 16) return -1;
    int start = (int)raw_start;
    int target = (int)raw_target;
    usz depth_limit = (usz)raw_depth;
    usz entry_count = (usz)raw_entries;

    int[MAX_VERTICES * MAX_NEIGHBORS] adjacency = {0};
    usz[MAX_VERTICES] degree_count = {0};
    bool[MAX_VERTICES] named = {false};
    usz max_vertex = 0;
    usz total_neighbors = 0;
    usz cursor = 4;
    for (usz entry = 0; entry < entry_count; entry++) {
        if (cursor + 2 > length) return -1;
        long raw_vertex = values[cursor++];
        long raw_degree = values[cursor++];
        if (raw_vertex < 1 || raw_vertex > 16 || raw_degree < 0 || raw_degree > 64) return -1;
        usz vertex = (usz)raw_vertex;
        usz degree = (usz)raw_degree;
        if (named[vertex - 1] || degree > length - cursor || total_neighbors + degree > MAX_NEIGHBORS) return -1;
        named[vertex - 1] = true;
        if (vertex > max_vertex) max_vertex = vertex;
        total_neighbors += degree;
        for (usz index = 0; index < degree; index++) {
            long raw_neighbor = values[cursor++];
            if (raw_neighbor < -16 || raw_neighbor > 16) return -1;
            if (raw_neighbor > (long)max_vertex) max_vertex = (usz)raw_neighbor;
            if (raw_neighbor >= 1) {
                usz slot = (vertex - 1) * MAX_NEIGHBORS + degree_count[vertex - 1];
                adjacency[slot] = (int)raw_neighbor;
                degree_count[vertex - 1]++;
            }
        }
    }
    if (cursor != length) return -1;
    if (max_vertex != 0 && ((usz)start > max_vertex || (usz)target > max_vertex)) return -1;

    int[MAX_PATH_LENGTH] path = {0};
    usz[MAX_PATH_LENGTH] next_neighbor = {0};
    usz path_length = 0;
    usz found_depth = 0;
    bool found = false;
    if (max_vertex != 0) {
        usz limit = 0;
        while (limit <= depth_limit && !found) {
            path_length = 1;
            path[0] = start;
            next_neighbor[0] = 0;
            if (start == target) {
                found = true;
                found_depth = 0;
                break;
            }
            while (path_length != 0 && !found) {
                usz frame = path_length - 1;
                int current = path[frame];
                if (frame >= limit || next_neighbor[frame] >= degree_count[current - 1]) {
                    path_length--;
                    continue;
                }
                usz slot = (usz)(current - 1) * MAX_NEIGHBORS + next_neighbor[frame];
                int neighbor = adjacency[slot];
                next_neighbor[frame]++;
                usz prior = 0;
                while (prior < path_length && path[prior] != neighbor) prior++;
                if (prior != path_length) continue;
                path[path_length] = neighbor;
                path_length++;
                if (neighbor == target) {
                    found = true;
                    found_depth = path_length - 1;
                } else {
                    next_neighbor[path_length - 1] = 0;
                }
            }
            limit++;
        }
    }

    long[MAX_OUTPUT_VALUES] result = {0};
    usz result_count = 3;
    result[0] = found ? 1 : 0;
    result[1] = found ? (long)found_depth : -1;
    result[2] = found ? (long)path_length : 0;
    if (found) {
        result_count += path_length;
        for (usz index = 0; index < path_length; index++) result[3 + index] = (long)path[index];
    }
    usz required = result_count * 8;
    if (output == null || output_capacity < required) return -2;
    for (usz index = 0; index < result_count; index++) store_i64_le(result[index], output, 8 * index);
    return (long)required;
}
