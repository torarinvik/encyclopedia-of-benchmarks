package iddfs

import "core:c"

MAX_VERTICES :: 16
MAX_NEIGHBORS :: 64
MAX_DEPTH :: 8
MAX_VALID_INPUT_LENGTH :: 4 + 2 * MAX_VERTICES + MAX_NEIGHBORS
MAX_PARSEABLE_INPUT_LENGTH :: MAX_VALID_INPUT_LENGTH + 1
MAX_PATH_LENGTH :: MAX_DEPTH + 1
MAX_OUTPUT_VALUES :: 3 + MAX_PATH_LENGTH

store_i64_le :: proc "c" (output: [^]u8, offset: int, value: i64) {
    bits := u64(value)
    for byte := 0; byte < 8; byte += 1 {
        output[offset + byte] = u8((bits >> u64(8 * byte)) & 255)
    }
}

@(export)
iddfs :: proc "c" (values: [^]i64, length: c.size_t,
        output: [^]u8, capacity: c.size_t) -> i64 {
    if values == nil || length < 4 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
    raw_start := values[0]
    raw_target := values[1]
    raw_depth := values[2]
    raw_entries := values[3]
    if raw_start < 1 || raw_start > MAX_VERTICES || raw_target < 1 || raw_target > MAX_VERTICES ||
        raw_depth < 0 || raw_depth > MAX_DEPTH || raw_entries < 0 || raw_entries > MAX_VERTICES do return -1
    start := int(raw_start)
    target := int(raw_target)
    depth_limit := int(raw_depth)
    entry_count := int(raw_entries)

    adjacency: [MAX_VERTICES * MAX_NEIGHBORS]i32 = {}
    degree_count: [MAX_VERTICES]int = {}
    named: [MAX_VERTICES]bool = {}
    max_vertex := 0
    total_neighbors := 0
    cursor := 4
    input_length := int(length)
    for _ in 0 .. entry_count {
        if cursor + 2 > input_length do return -1
        raw_vertex := values[cursor]
        cursor += 1
        raw_degree := values[cursor]
        cursor += 1
        if raw_vertex < 1 || raw_vertex > MAX_VERTICES || raw_degree < 0 || raw_degree > MAX_NEIGHBORS do return -1
        vertex := int(raw_vertex)
        degree := int(raw_degree)
        if named[vertex - 1] || degree > input_length - cursor || total_neighbors + degree > MAX_NEIGHBORS do return -1
        named[vertex - 1] = true
        if vertex > max_vertex do max_vertex = vertex
        total_neighbors += degree
        for _ in 0 .. degree {
            raw_neighbor := values[cursor]
            cursor += 1
            if raw_neighbor < -MAX_VERTICES || raw_neighbor > MAX_VERTICES do return -1
            if raw_neighbor > i64(max_vertex) do max_vertex = int(raw_neighbor)
            if raw_neighbor >= 1 {
                slot := (vertex - 1) * MAX_NEIGHBORS + degree_count[vertex - 1]
                adjacency[slot] = i32(raw_neighbor)
                degree_count[vertex - 1] += 1
            }
        }
    }
    if cursor != input_length do return -1
    if max_vertex != 0 && (start > max_vertex || target > max_vertex) do return -1

    path: [MAX_PATH_LENGTH]int = {}
    next_neighbor: [MAX_PATH_LENGTH]int = {}
    path_length := 0
    found_depth := 0
    found := false
    if max_vertex != 0 {
        for limit := 0; limit <= depth_limit && !found; limit += 1 {
            path_length = 1
            path[0] = start
            next_neighbor[0] = 0
            if start == target {
                found = true
                found_depth = 0
                break
            }
            for path_length > 0 && !found {
                frame := path_length - 1
                current := path[frame]
                if frame >= limit || next_neighbor[frame] >= degree_count[current - 1] {
                    path_length -= 1
                    continue
                }
                slot := (current - 1) * MAX_NEIGHBORS + next_neighbor[frame]
                neighbor := int(adjacency[slot])
                next_neighbor[frame] += 1
                prior := 0
                for prior < path_length && path[prior] != neighbor { prior += 1 }
                if prior != path_length { continue }
                path[path_length] = neighbor
                path_length += 1
                if neighbor == target {
                    found = true
                    found_depth = path_length - 1
                } else {
                    next_neighbor[path_length - 1] = 0
                }
            }
        }
    }

    result: [MAX_OUTPUT_VALUES]i64 = {}
    result_count := 3
    result[0] = 0
    result[1] = -1
    result[2] = 0
    if found {
        result[0] = 1
        result[1] = i64(found_depth)
        result[2] = i64(path_length)
        result_count += path_length
        for index := 0; index < path_length; index += 1 { result[3 + index] = i64(path[index]) }
    }
    required := result_count * 8
    if output == nil || capacity < c.size_t(required) do return -2
    for index := 0; index < result_count; index += 1 { store_i64_le(output, 8 * index, result[index]) }
    return i64(required)
}
