/// Minimum edge coloring of a bounded bipartite multigraph.
const MAX_SIDE: usize = 5;
const MAX_EDGES: usize = 10;
const MAX_INPUT_LENGTH: usize = 23;
const MAX_OUTPUT_BYTES: usize = 88;

fn augment(left: usize, side: usize, multiplicity: *const [MAX_SIDE * MAX_SIDE]i64,
    seen: *[MAX_SIDE]bool, match_right: *[MAX_SIDE]i32) bool {
    for (0..side) |right| {
        const index = left * MAX_SIDE + right;
        if (multiplicity.*[index] == 0 or seen.*[right]) continue;
        seen.*[right] = true;
        const mate = match_right.*[right];
        if (mate < 0 or augment(@intCast(mate), side, multiplicity, seen, match_right)) {
            match_right.*[right] = @intCast(left);
            return true;
        }
    }
    return false;
}

fn storeU64Le(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: u64) void {
    for (0..8) |byte| output.*[offset + byte] = @intCast((value >> @intCast(byte * 8)) & 0xff);
}

/// Packed input `[L, R, M, (left, right)*M]`; writes `[K, colors...]` as LE u64s.
export fn bipartite_edge_coloring(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const left_value = input[0];
    const right_value = input[1];
    const edge_value = input[2];
    if (left_value < 1 or left_value > MAX_SIDE or right_value < 1 or right_value > MAX_SIDE or
        edge_value < 1 or edge_value > MAX_EDGES) return -1;
    const left_count: usize = @intCast(left_value);
    const right_count: usize = @intCast(right_value);
    const edge_count: usize = @intCast(edge_value);
    if (length != 3 + 2 * edge_count) return -1;

    var multiplicity = [_]i64{0} ** (MAX_SIDE * MAX_SIDE);
    var original_remaining = [_]i64{0} ** (MAX_SIDE * MAX_SIDE);
    var left_degree = [_]usize{0} ** MAX_SIDE;
    var right_degree = [_]usize{0} ** MAX_SIDE;
    var edge_left = [_]usize{0} ** MAX_EDGES;
    var edge_right = [_]usize{0} ** MAX_EDGES;
    for (0..edge_count) |edge| {
        const left = input[3 + 2 * edge];
        const right = input[4 + 2 * edge];
        if (left < 0 or left >= left_value or right < 0 or right >= right_value) return -1;
        const u: usize = @intCast(left);
        const v: usize = @intCast(right);
        edge_left[edge] = u;
        edge_right[edge] = v;
        const index = u * MAX_SIDE + v;
        multiplicity[index] += 1;
        original_remaining[index] += 1;
        left_degree[u] += 1;
        right_degree[v] += 1;
    }

    const side = @max(left_count, right_count);
    var maximum_degree: usize = 0;
    for (0..side) |vertex| maximum_degree = @max(maximum_degree, @max(left_degree[vertex], right_degree[vertex]));
    while (true) {
        var left: usize = 0;
        while (left < side and left_degree[left] == maximum_degree) : (left += 1) {}
        if (left == side) break;
        var right: usize = 0;
        while (right < side and right_degree[right] == maximum_degree) : (right += 1) {}
        if (right == side) return -1;
        const index = left * MAX_SIDE + right;
        multiplicity[index] += 1;
        left_degree[left] += 1;
        right_degree[right] += 1;
    }

    var colors = [_]i64{-1} ** MAX_EDGES;
    for (0..maximum_degree) |color| {
        var match_right = [_]i32{-1} ** MAX_SIDE;
        for (0..side) |left| {
            var seen = [_]bool{false} ** MAX_SIDE;
            if (!augment(left, side, &multiplicity, &seen, &match_right)) return -1;
        }
        for (0..side) |right| {
            const matched = match_right[right];
            if (matched < 0) return -1;
            const left: usize = @intCast(matched);
            const index = left * MAX_SIDE + right;
            if (original_remaining[index] > 0) {
                var edge: usize = 0;
                while (edge < edge_count and (colors[edge] >= 0 or edge_left[edge] != left or edge_right[edge] != right)) : (edge += 1) {}
                if (edge == edge_count) return -1;
                colors[edge] = @intCast(color);
                original_remaining[index] -= 1;
            }
            multiplicity[index] -= 1;
        }
    }

    const bytes = 8 * (edge_count + 1);
    if (output == null or capacity < bytes) return -2;
    var staged = [_]u8{0} ** MAX_OUTPUT_BYTES;
    storeU64Le(&staged, 0, maximum_degree);
    for (0..edge_count) |edge| storeU64Le(&staged, 8 * (edge + 1), @intCast(colors[edge]));
    for (0..bytes) |byte| output[byte] = staged[byte];
    return @intCast(bytes);
}
