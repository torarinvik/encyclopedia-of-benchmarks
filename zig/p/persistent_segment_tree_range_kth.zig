const MAX_N: usize = 32;
const MAX_Q: usize = 32;
const MAX_INPUT_LENGTH: usize = 131;
const MAX_NODES: usize = 193;
const INVALID_RESULT: i64 = -9223372036854775807 - 1;

export fn persistent_segment_tree_range_kth(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or input[1] < 0 or input[1] > @as(i64, @intCast(MAX_Q))) return INVALID_RESULT;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + n + 3 * q) return INVALID_RESULT;

    var coordinates = [_]i64{0} ** MAX_N;
    for (0..n) |i| {
        const value = input[2 + i];
        if (value < -1000 or value > 1000) return INVALID_RESULT;
        coordinates[i] = value;
    }
    for (1..n) |i| {
        const value = coordinates[i];
        var j = i;
        while (j > 0 and coordinates[j - 1] > value) : (j -= 1) {
            coordinates[j] = coordinates[j - 1];
        }
        coordinates[j] = value;
    }
    var distinct: usize = 0;
    for (0..n) |i| {
        if (distinct == 0 or coordinates[i] != coordinates[distinct - 1]) {
            coordinates[distinct] = coordinates[i];
            distinct += 1;
        }
    }
    const query_offset = 2 + n;
    for (0..q) |qi| {
        const at = query_offset + 3 * qi;
        const left = input[at];
        const right = input[at + 1];
        const k = input[at + 2];
        if (left < 0 or right < left or right >= @as(i64, @intCast(n)) or k < 1 or k > right - left + 1) return INVALID_RESULT;
    }

    var left_child = [_]i32{0} ** MAX_NODES;
    var right_child = [_]i32{0} ** MAX_NODES;
    var counts = [_]i32{0} ** MAX_NODES;
    var roots = [_]i32{0} ** (MAX_N + 1);
    var node_count: usize = 1;
    for (0..n) |i| {
        const value = input[2 + i];
        var low: usize = 0;
        var high = distinct;
        while (low < high) {
            const middle = low + (high - low) / 2;
            if (coordinates[middle] < value) low = middle + 1 else high = middle;
        }
        const rank = low;
        const previous_root: usize = @intCast(roots[i]);
        if (node_count >= MAX_NODES) return INVALID_RESULT;
        const new_root = node_count;
        node_count += 1;
        left_child[new_root] = left_child[previous_root];
        right_child[new_root] = right_child[previous_root];
        counts[new_root] = counts[previous_root] + 1;
        var old_node = previous_root;
        var new_node = new_root;
        low = 0;
        high = distinct;
        while (high - low > 1) {
            const middle = low + (high - low) / 2;
            const old_child: usize = @intCast(if (rank < middle) left_child[old_node] else right_child[old_node]);
            if (node_count >= MAX_NODES) return INVALID_RESULT;
            const new_child = node_count;
            node_count += 1;
            left_child[new_child] = left_child[old_child];
            right_child[new_child] = right_child[old_child];
            counts[new_child] = counts[old_child] + 1;
            if (rank < middle) {
                left_child[new_node] = @intCast(new_child);
                high = middle;
            } else {
                right_child[new_node] = @intCast(new_child);
                low = middle;
            }
            old_node = old_child;
            new_node = new_child;
        }
        roots[i + 1] = @intCast(new_root);
    }

    var checksum: i64 = 0;
    for (0..q) |qi| {
        const at = query_offset + 3 * qi;
        const left: usize = @intCast(input[at]);
        const right: usize = @intCast(input[at + 1]);
        var k: i32 = @intCast(input[at + 2]);
        var before: usize = @intCast(roots[left]);
        var after: usize = @intCast(roots[right + 1]);
        var low: usize = 0;
        var high = distinct;
        while (high - low > 1) {
            const middle = low + (high - low) / 2;
            const in_left: usize = @intCast(left_child[after]);
            const out_left: usize = @intCast(left_child[before]);
            const left_count = counts[in_left] - counts[out_left];
            if (k <= left_count) {
                before = out_left;
                after = in_left;
                high = middle;
            } else {
                k -= left_count;
                before = @intCast(right_child[before]);
                after = @intCast(right_child[after]);
                low = middle;
            }
        }
        checksum += (@as(i64, @intCast(qi)) + 1) * coordinates[low];
    }
    return checksum;
}
