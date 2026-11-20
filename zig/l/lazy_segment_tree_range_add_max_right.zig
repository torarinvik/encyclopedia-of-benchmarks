const MAX_VALID_LENGTH: usize = 66;
const MAX_PARSEABLE_LENGTH: usize = 67;
const TREE_LENGTH: usize = 64;

fn apply(tree: *[TREE_LENGTH]i64, pending: *[TREE_LENGTH]i64,
    node: usize, segment_length: usize, delta: i64) void {
    tree[node] += delta * @as(i64, @intCast(segment_length));
    pending[node] += delta;
}

fn push(tree: *[TREE_LENGTH]i64, pending: *[TREE_LENGTH]i64,
    node: usize, segment_length: usize) void {
    if (segment_length > 1 and pending[node] != 0) {
        const half = segment_length / 2;
        const delta = pending[node];
        apply(tree, pending, 2 * node, half, delta);
        apply(tree, pending, 2 * node + 1, half, delta);
        pending[node] = 0;
    }
}

fn rangeAdd(tree: *[TREE_LENGTH]i64, pending: *[TREE_LENGTH]i64,
    node: usize, low: usize, high: usize, query_low: usize,
    query_high: usize, delta: i64) void {
    if (query_low >= query_high) return;
    if (query_high <= low or high <= query_low) return;
    if (query_low <= low and high <= query_high) {
        apply(tree, pending, node, high - low, delta);
        return;
    }
    push(tree, pending, node, high - low);
    const middle = (low + high) / 2;
    if (query_low < middle) rangeAdd(tree, pending, 2 * node, low, middle, query_low, query_high, delta);
    if (query_high > middle) rangeAdd(tree, pending, 2 * node + 1, middle, high, query_low, query_high, delta);
    tree[node] = tree[2 * node] + tree[2 * node + 1];
}

fn maxRight(tree: *[TREE_LENGTH]i64, pending: *[TREE_LENGTH]i64,
    node: usize, low: usize, high: usize, n: usize, left: usize,
    limit: i64, accumulated: *i64) usize {
    if (high <= left) return high;
    if (low >= n) return n;
    if (left <= low and high <= n and accumulated.* + tree[node] <= limit) {
        accumulated.* += tree[node];
        return high;
    }
    if (high - low == 1) return low;
    push(tree, pending, node, high - low);
    const middle = (low + high) / 2;
    const first = maxRight(tree, pending, 2 * node, low, middle, n, left, limit, accumulated);
    if (first < middle and first >= left) return first;
    return maxRight(tree, pending, 2 * node + 1, middle, high, n, left, limit, accumulated);
}

export fn lazy_segment_tree_range_add_max_right(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_PARSEABLE_LENGTH) return -1;
    if (input[0] < 1 or input[0] > 16 or input[1] < 0 or input[1] > 12) return -1;
    const n: usize = @intCast(input[0]);
    const operations: usize = @intCast(input[1]);
    if (length != 2 + n + 4 * operations or length > MAX_VALID_LENGTH) return -1;
    for (0..n) |i| {
        if (input[2 + i] < 0 or input[2 + i] > 31) return -1;
    }
    for (0..operations) |operation| {
        const p = 2 + n + 4 * operation;
        const opcode = input[p];
        const left = input[p + 1];
        const right = input[p + 2];
        const extra = input[p + 3];
        if (opcode == 0) {
            if (left < 0 or left > @as(i64, @intCast(n)) or right < left
                or right > @as(i64, @intCast(n)) or extra < 0 or extra > 31) return -1;
        } else if (opcode == 1) {
            if (left < 0 or left > @as(i64, @intCast(n)) or right < 0 or right > 8192 or extra != 0) return -1;
        } else return -1;
    }

    var base: usize = 1;
    while (base < n) base *= 2;
    var tree: [TREE_LENGTH]i64 = @splat(0);
    var pending: [TREE_LENGTH]i64 = @splat(0);
    for (0..n) |i| tree[base + i] = input[2 + i];
    var node = base;
    while (node > 1) {
        node -= 1;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    var query_index: usize = 0;
    var result: i64 = 0;
    for (0..operations) |operation| {
        const p = 2 + n + 4 * operation;
        const left: usize = @intCast(input[p + 1]);
        const right: usize = @intCast(input[p + 2]);
        if (input[p] == 0) {
            rangeAdd(&tree, &pending, 1, 0, base, left, right, input[p + 3]);
        } else {
            var accumulated: i64 = 0;
            const boundary = maxRight(&tree, &pending, 1, 0, base, n, left, @as(i64, @intCast(right)), &accumulated);
            result |= @as(i64, @intCast(boundary)) << @intCast(5 * query_index);
            query_index += 1;
        }
    }
    return result;
}
