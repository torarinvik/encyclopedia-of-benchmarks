const MAX_VERTICES: usize = 16;
const MAX_NEIGHBORS: usize = 64;
const MAX_DEPTH: usize = 8;
const MAX_VALID_INPUT_LENGTH: usize = 4 + 2 * MAX_VERTICES + MAX_NEIGHBORS;
const MAX_PARSEABLE_INPUT_LENGTH: usize = MAX_VALID_INPUT_LENGTH + 1;
const MAX_PATH_LENGTH: usize = MAX_DEPTH + 1;
const MAX_OUTPUT_VALUES: usize = 3 + MAX_PATH_LENGTH;
const MAX_VERTICES_I64: i64 = 16;
const MAX_NEIGHBORS_I64: i64 = 64;
const MAX_DEPTH_I64: i64 = 8;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn iddfs(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const raw_start = values[0];
    const raw_target = values[1];
    const raw_depth = values[2];
    const raw_entries = values[3];
    if (raw_start < 1 or raw_start > MAX_VERTICES_I64 or raw_target < 1 or raw_target > MAX_VERTICES_I64 or
        raw_depth < 0 or raw_depth > MAX_DEPTH_I64 or raw_entries < 0 or raw_entries > MAX_VERTICES_I64) return -1;
    const start: usize = @intCast(raw_start);
    const target: usize = @intCast(raw_target);
    const depth_limit: usize = @intCast(raw_depth);
    const entry_count: usize = @intCast(raw_entries);

    var adjacency: [MAX_VERTICES][MAX_NEIGHBORS]i32 = undefined;
    var degree_count: [MAX_VERTICES]usize = @splat(0);
    var named: [MAX_VERTICES]bool = @splat(false);
    var max_vertex: usize = 0;
    var total_neighbors: usize = 0;
    var cursor: usize = 4;
    for (0..entry_count) |_| {
        if (cursor + 2 > length) return -1;
        const raw_vertex = values[cursor]; cursor += 1;
        const raw_degree = values[cursor]; cursor += 1;
        if (raw_vertex < 1 or raw_vertex > MAX_VERTICES_I64 or raw_degree < 0 or raw_degree > MAX_NEIGHBORS_I64) return -1;
        const vertex: usize = @intCast(raw_vertex);
        const degree: usize = @intCast(raw_degree);
        if (named[vertex - 1] or degree > length - cursor or total_neighbors + degree > MAX_NEIGHBORS) return -1;
        named[vertex - 1] = true;
        max_vertex = @max(max_vertex, vertex);
        total_neighbors += degree;
        for (0..degree) |_| {
            const raw_neighbor = values[cursor]; cursor += 1;
            if (raw_neighbor < -MAX_VERTICES_I64 or raw_neighbor > MAX_VERTICES_I64) return -1;
            if (raw_neighbor > @as(i64, @intCast(max_vertex))) max_vertex = @intCast(raw_neighbor);
            if (raw_neighbor >= 1) {
                adjacency[vertex - 1][degree_count[vertex - 1]] = @intCast(raw_neighbor);
                degree_count[vertex - 1] += 1;
            }
        }
    }
    if (cursor != length) return -1;
    if (max_vertex != 0 and (start > max_vertex or target > max_vertex)) return -1;

    var path: [MAX_PATH_LENGTH]i64 = undefined;
    var next_neighbor: [MAX_PATH_LENGTH]usize = @splat(0);
    var path_length: usize = 0;
    var found_depth: usize = 0;
    var found = false;
    if (max_vertex != 0) {
        var limit: usize = 0;
        while (limit <= depth_limit and !found) : (limit += 1) {
            path_length = 1;
            path[0] = @intCast(start);
            next_neighbor[0] = 0;
            if (start == target) {
                found = true;
                found_depth = 0;
                break;
            }
            while (path_length != 0 and !found) {
                const frame = path_length - 1;
                const current: usize = @intCast(path[frame]);
                if (frame >= limit or next_neighbor[frame] >= degree_count[current - 1]) {
                    path_length -= 1;
                    continue;
                }
                const neighbor = adjacency[current - 1][next_neighbor[frame]];
                next_neighbor[frame] += 1;
                var prior: usize = 0;
                while (prior < path_length and path[prior] != neighbor) : (prior += 1) {}
                if (prior != path_length) continue;
                path[path_length] = neighbor;
                path_length += 1;
                if (neighbor == target) {
                    found = true;
                    found_depth = path_length - 1;
                } else {
                    next_neighbor[path_length - 1] = 0;
                }
            }
        }
    }

    var result: [MAX_OUTPUT_VALUES]i64 = @splat(0);
    var result_count: usize = 3;
    result[0] = if (found) 1 else 0;
    result[1] = if (found) @intCast(found_depth) else -1;
    result[2] = if (found) @intCast(path_length) else 0;
    if (found) {
        result_count += path_length;
        for (0..path_length) |index| result[3 + index] = path[index];
    }
    const required = result_count * 8;
    if (output == null or output_capacity < required) return -2;
    for (0..result_count) |index| storeI64Le(output, 8 * index, result[index]);
    return @intCast(required);
}
