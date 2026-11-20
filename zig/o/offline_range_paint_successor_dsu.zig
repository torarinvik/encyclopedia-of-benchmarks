const max_n: usize = 64;
const max_q: usize = 64;
const max_input_values: usize = 195;

fn findSuccessor(parent: *[max_n + 1]usize, start: usize) usize {
    var node = start;
    var root = node;
    while (parent[root] != root) root = parent[root];
    while (parent[node] != node) {
        const next = parent[node];
        parent[node] = root;
        node = next;
    }
    return root;
}

export fn offline_range_paint_successor_dsu(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input_values) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n)) or input[1] < 0 or input[1] > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(input[0]);
    const q: usize = @intCast(input[1]);
    if (length != 2 + 3 * q) return -1;
    var left = [_]i64{0} ** max_q;
    var right = [_]i64{0} ** max_q;
    var color = [_]i64{0} ** max_q;
    for (0..q) |j| {
        left[j] = input[2 + 3 * j];
        right[j] = input[3 + 3 * j];
        color[j] = input[4 + 3 * j];
        if (left[j] < 0 or left[j] > right[j] or right[j] >= @as(i64, @intCast(n)) or color[j] < -1000 or color[j] > 1000) return -1;
    }
    var parent = [_]usize{0} ** (max_n + 1);
    var final_color = [_]i64{0} ** max_n;
    for (0..n + 1) |i| parent[i] = i;
    var j = q;
    while (j > 0) {
        j -= 1;
        var cell = findSuccessor(&parent, @intCast(left[j]));
        while (cell <= @as(usize, @intCast(right[j]))) {
            final_color[cell] = color[j];
            parent[cell] = findSuccessor(&parent, cell + 1);
            cell = findSuccessor(&parent, cell);
        }
    }
    var checksum: i64 = 0;
    for (0..n) |i| checksum += @as(i64, @intCast(i + 1)) * (final_color[i] + 1001);
    return checksum;
}
