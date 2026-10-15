const MAX_VERTICES: usize = 1000;

fn findRoot(parents: []i32, node_value: i32) i32 {
    var node = node_value;
    var root = node;
    while (parents[@intCast(root)] != root) root = parents[@intCast(root)];
    while (parents[@intCast(node)] != node) {
        const next = parents[@intCast(node)];
        parents[@intCast(node)] = root;
        node = next;
    }
    return root;
}

/// Return the edge that first closes the cycle under input-order union-find.
export fn redundant_connection(values: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 6 or length > 2 * MAX_VERTICES or length % 2 != 0) return -1;
    const edge_count = length / 2;
    for (0..length) |index| {
        if (values[index] < 1 or values[index] > @as(i64, @intCast(edge_count))) return -1;
    }
    for (0..edge_count) |edge| {
        if (values[2 * edge] == values[2 * edge + 1]) return -1;
    }

    var parents: [MAX_VERTICES + 1]i32 = undefined;
    for (0..edge_count + 1) |node| parents[node] = @intCast(node);
    var redundant_left: i64 = 0;
    var redundant_right: i64 = 0;
    var redundant_count: usize = 0;
    for (0..edge_count) |edge| {
        const left: i32 = @intCast(values[2 * edge]);
        const right: i32 = @intCast(values[2 * edge + 1]);
        const left_root = findRoot(parents[0 .. edge_count + 1], left);
        const right_root = findRoot(parents[0 .. edge_count + 1], right);
        if (left_root == right_root) {
            redundant_left = left;
            redundant_right = right;
            redundant_count += 1;
        } else {
            parents[@intCast(left_root)] = right_root;
        }
    }
    if (redundant_count != 1) return -1;
    if (output_capacity < 8) return -2;
    const endpoints = [_]i64{ redundant_left, redundant_right };
    for (0..2) |endpoint| {
        const bytes = @as(i32, @intCast(endpoints[endpoint]));
        for (0..4) |byte| output[endpoint * 4 + byte] = @truncate(@as(u32, @bitCast(bytes)) >> @intCast(byte * 8));
    }
    return 2;
}
