const MAX_N: usize = 48;
const MAX_NODES: usize = 2 * MAX_N - 1;
const GRID: usize = MAX_N * MAX_N;

fn storeI64Le(output: [*]u8, offset: usize, value: i64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @truncate(bits & 255);
        bits >>= 8;
    }
}

fn intervalsOverlap(left_a: usize, right_a: usize, left_b: usize, right_b: usize) bool {
    return (left_a < left_b and left_b <= right_a and right_a < right_b) or
        (left_b < left_a and left_a <= right_b and right_b < right_a);
}

export fn common_interval_decomposition_tree(input_opt: ?[*]const i64,
    length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > 1 + MAX_N) return -1;
    const input = input_opt.?;
    const n_value = input[0];
    if (n_value < 1 or n_value > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(n_value);
    if (length != n + 1) return -1;

    var seen = [_]bool{false} ** MAX_N;
    for (0..n) |i| {
        const value = input[i + 1];
        if (value < 0 or value >= n_value) return -1;
        const value_index: usize = @intCast(value);
        if (seen[value_index]) return -1;
        seen[value_index] = true;
    }

    var connected = [_]bool{false} ** GRID;
    var strong = [_]bool{false} ** GRID;
    for (0..n) |left| {
        var minimum: i64 = n_value;
        var maximum: i64 = -1;
        var right = left;
        while (right < n) : (right += 1) {
            const value = input[right + 1];
            minimum = @min(minimum, value);
            maximum = @max(maximum, value);
            const slot = left * MAX_N + right;
            if (maximum - minimum == @as(i64, @intCast(right - left))) {
                connected[slot] = true;
                strong[slot] = true;
            }
        }
    }

    for (0..n) |left_a| {
        var right_a = left_a;
        while (right_a < n) : (right_a += 1) {
            const slot_a = left_a * MAX_N + right_a;
            if (!connected[slot_a]) continue;
            for (0..n) |left_b| {
                var right_b = left_b;
                while (right_b < n) : (right_b += 1) {
                    const slot_b = left_b * MAX_N + right_b;
                    if (slot_b <= slot_a or !connected[slot_b]) continue;
                    if (intervalsOverlap(left_a, right_a, left_b, right_b)) {
                        strong[slot_a] = false;
                        strong[slot_b] = false;
                    }
                }
            }
        }
    }

    var node_left = [_]i64{0} ** MAX_NODES;
    var node_right = [_]i64{0} ** MAX_NODES;
    var parent = [_]i64{-1} ** MAX_NODES;
    var node_type = [_]i64{0} ** MAX_NODES;
    var node_count: usize = 0;
    var span = n;
    while (span > 0) : (span -= 1) {
        var left: usize = 0;
        while (left + span <= n) : (left += 1) {
            const right = left + span - 1;
            if (!strong[left * MAX_N + right]) continue;
            node_left[node_count] = @intCast(left);
            node_right[node_count] = @intCast(right);
            node_count += 1;
        }
    }
    if (node_count == 0 or node_count > MAX_NODES) return -1;

    for (0..node_count) |node| {
        const node_span = node_right[node] - node_left[node] + 1;
        var best_span: i64 = n_value + 1;
        for (0..node_count) |candidate| {
            const candidate_span = node_right[candidate] - node_left[candidate] + 1;
            if (candidate_span > node_span and candidate_span < best_span and
                node_left[candidate] <= node_left[node] and
                node_right[node] <= node_right[candidate]) {
                parent[node] = @intCast(candidate);
                best_span = candidate_span;
            }
        }
    }

    for (0..node_count) |node| {
        var children = [_]usize{0} ** MAX_N;
        var child_count: usize = 0;
        for (0..node_count) |child| {
            if (parent[child] != @as(i64, @intCast(node))) continue;
            var at = child_count;
            while (at > 0 and node_left[children[at - 1]] > node_left[child]) : (at -= 1) {
                children[at] = children[at - 1];
            }
            children[at] = child;
            child_count += 1;
        }

        for (0..child_count) |first| {
            var last = first;
            while (last < child_count) : (last += 1) {
                const left: usize = @intCast(node_left[children[first]]);
                const right: usize = @intCast(node_right[children[last]]);
                var minimum: i64 = n_value;
                var maximum: i64 = -1;
                var position = left;
                while (position <= right) : (position += 1) {
                    const value = input[position + 1];
                    minimum = @min(minimum, value);
                    maximum = @max(maximum, value);
                }
                if (maximum - minimum != @as(i64, @intCast(right - left))) {
                    node_type[node] = 1;
                    break;
                }
            }
            if (node_type[node] != 0) break;
        }
    }

    const output_bytes = (1 + 4 * node_count) * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    storeI64Le(output, 0, @intCast(node_count));
    for (0..node_count) |node| {
        const offset = 8 + 32 * node;
        storeI64Le(output, offset, parent[node]);
        storeI64Le(output, offset + 8, node_left[node]);
        storeI64Le(output, offset + 16, node_right[node]);
        storeI64Le(output, offset + 24, node_type[node]);
    }
    return @intCast(output_bytes);
}
