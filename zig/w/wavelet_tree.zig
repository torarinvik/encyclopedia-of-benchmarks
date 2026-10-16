const Node = struct {
    low: i64,
    high: i64,
    left: i32,
    right: i32,
    prefix: [65]usize,
};
const Tree = struct { nodes: [768]Node = undefined, used: usize = 0 };

fn build(tree: *Tree, values: []const i64, low: i64, high: i64) i32 {
    const id: i32 = @intCast(tree.used);
    tree.used += 1;
    const slot: usize = @intCast(id);
    tree.nodes[slot].low = low;
    tree.nodes[slot].high = high;
    tree.nodes[slot].left = -1;
    tree.nodes[slot].right = -1;
    tree.nodes[slot].prefix[0] = 0;
    if (low == high or values.len == 0) return id;
    const mid = low + @divTrunc(high - low, 2);
    var left_values: [64]i64 = undefined;
    var right_values: [64]i64 = undefined;
    var left_count: usize = 0;
    var right_count: usize = 0;
    for (values, 0..) |value, i| {
        if (value <= mid) {
            left_values[left_count] = value;
            left_count += 1;
        } else {
            right_values[right_count] = value;
            right_count += 1;
        }
        tree.nodes[slot].prefix[i + 1] = left_count;
    }
    if (left_count > 0) tree.nodes[slot].left = build(tree, left_values[0..left_count], low, mid);
    if (right_count > 0) tree.nodes[slot].right = build(tree, right_values[0..right_count], mid + 1, high);
    return id;
}

fn rankPrefix(tree: *const Tree, node_id: i32, value: i64, count: usize) i64 {
    if (node_id < 0 or count == 0) return 0;
    const node = tree.nodes[@intCast(node_id)];
    if (node.low == node.high) return if (node.low == value) @intCast(count) else 0;
    const mid = node.low + @divTrunc(node.high - node.low, 2);
    const left_count = node.prefix[count];
    if (value <= mid) return rankPrefix(tree, node.left, value, left_count);
    return rankPrefix(tree, node.right, value, count - left_count);
}

fn quantile(tree: *const Tree, node_id: i32, left: usize, right: usize, k: usize) i64 {
    const node = tree.nodes[@intCast(node_id)];
    if (node.low == node.high) return node.low;
    const left_before = node.prefix[left];
    const left_after = node.prefix[right];
    const in_left = left_after - left_before;
    if (k < in_left) return quantile(tree, node.left, left_before, left_after, k);
    return quantile(tree, node.right, left - left_before, right - left_after, k - in_left);
}

fn rangeCount(tree: *const Tree, node_id: i32, left: usize, right: usize, low: i64, high: i64) i64 {
    if (node_id < 0 or left >= right) return 0;
    const node = tree.nodes[@intCast(node_id)];
    if (high < node.low or low > node.high) return 0;
    if (low <= node.low and node.high <= high) return @intCast(right - left);
    if (node.low == node.high) return 0;
    const left_before = node.prefix[left];
    const left_after = node.prefix[right];
    return rangeCount(tree, node.left, left_before, left_after, low, high) +
        rangeCount(tree, node.right, left - left_before, right - left_after, low, high);
}

export fn wavelet_tree_benchmark(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > 706) return -1;
    const v = values.?;
    if (v[0] < 1 or v[0] > 64) return -1;
    const n: usize = @intCast(v[0]);
    if (length < n + 2) return -1;
    const data = v[1 .. n + 1];
    var low = data[0];
    var high = data[0];
    for (data) |value| {
        if (value < -1000 or value > 1000) return -1;
        if (value < low) low = value;
        if (value > high) high = value;
    }
    if (v[n + 1] < 0 or v[n + 1] > 128) return -1;
    const q: usize = @intCast(v[n + 1]);
    if (length != n + 2 + 5 * q) return -1;
    var tree = Tree{};
    const root = build(&tree, data, low, high);
    var total: i64 = 0;
    for (0..q) |j| {
        const p = n + 2 + 5 * j;
        const op = v[p];
        const a = v[p + 1];
        const b = v[p + 2];
        const c = v[p + 3];
        const d = v[p + 4];
        var answer: i64 = 0;
        if (op == 0) {
            if (a < -1000 or a > 1000 or b < -1 or b >= @as(i64, @intCast(n))) return -1;
            answer = rankPrefix(&tree, root, a, @intCast(b + 1));
        } else if (op == 1) {
            if (a < 0 or b < a or b >= @as(i64, @intCast(n)) or c < 0 or c > b - a) return -1;
            answer = quantile(&tree, root, @intCast(a), @intCast(b + 1), @intCast(c));
        } else if (op == 2) {
            if (a < 0 or b < a or b >= @as(i64, @intCast(n)) or c > d or c < -1000 or d > 1000) return -1;
            answer = rangeCount(&tree, root, @intCast(a), @intCast(b + 1), c, d);
        } else return -1;
        total += @as(i64, @intCast(j + 1)) * (answer + 1_000_001);
    }
    return total;
}
