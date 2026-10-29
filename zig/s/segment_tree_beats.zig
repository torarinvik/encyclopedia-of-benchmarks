const MAX_ITEMS: usize = 64;
const MAX_OPERATIONS: usize = 128;
const MAX_INPUT_VALUES: usize = 2 + MAX_ITEMS + 4 * MAX_OPERATIONS;
const TREE_SIZE: usize = 4 * MAX_ITEMS;
const VALUE_LIMIT: i64 = 1_000_000;
const INF: i64 = 2_305_843_009_213_693_951;
const QUERY_OFFSET: i64 = 8_256_000_001;

const Node = struct {
    sum: i64 = 0,
    max1: i64 = 0,
    max2: i64 = -INF,
    min1: i64 = 0,
    min2: i64 = INF,
    add: i64 = 0,
    max_count: usize = 0,
    min_count: usize = 0,
};

fn pull(tree: *[TREE_SIZE]Node, node: usize) void {
    const left = tree[2 * node];
    const right = tree[2 * node + 1];
    tree[node].sum = left.sum + right.sum;
    tree[node].add = 0;
    if (left.max1 == right.max1) {
        tree[node].max1 = left.max1;
        tree[node].max2 = @max(left.max2, right.max2);
        tree[node].max_count = left.max_count + right.max_count;
    } else if (left.max1 > right.max1) {
        tree[node].max1 = left.max1;
        tree[node].max2 = @max(left.max2, right.max1);
        tree[node].max_count = left.max_count;
    } else {
        tree[node].max1 = right.max1;
        tree[node].max2 = @max(left.max1, right.max2);
        tree[node].max_count = right.max_count;
    }
    if (left.min1 == right.min1) {
        tree[node].min1 = left.min1;
        tree[node].min2 = @min(left.min2, right.min2);
        tree[node].min_count = left.min_count + right.min_count;
    } else if (left.min1 < right.min1) {
        tree[node].min1 = left.min1;
        tree[node].min2 = @min(left.min2, right.min1);
        tree[node].min_count = left.min_count;
    } else {
        tree[node].min1 = right.min1;
        tree[node].min2 = @min(left.min1, right.min2);
        tree[node].min_count = right.min_count;
    }
}

fn build(tree: *[TREE_SIZE]Node, values: [*c]const i64, offset: usize,
    node: usize, low: usize, high: usize) void {
    if (high - low == 1) {
        const value = values[offset + low];
        tree[node] = .{ .sum = value, .max1 = value, .max2 = -INF, .min1 = value, .min2 = INF, .add = 0, .max_count = 1, .min_count = 1 };
        return;
    }
    const middle = low + (high - low) / 2;
    build(tree, values, offset, 2 * node, low, middle);
    build(tree, values, offset, 2 * node + 1, middle, high);
    pull(tree, node);
}

fn applyAdd(item: *Node, length: usize, delta: i64) void {
    item.sum += delta * @as(i64, @intCast(length));
    item.max1 += delta;
    item.min1 += delta;
    if (item.max2 != -INF) item.max2 += delta;
    if (item.min2 != INF) item.min2 += delta;
    item.add += delta;
}

fn applyChmin(item: *Node, ceiling: i64) void {
    if (item.max1 <= ceiling) return;
    item.sum += (ceiling - item.max1) * @as(i64, @intCast(item.max_count));
    if (item.min1 == item.max1) {
        item.min1 = ceiling;
    } else if (item.min2 == item.max1) {
        item.min2 = ceiling;
    }
    item.max1 = ceiling;
}

fn applyChmax(item: *Node, floor: i64) void {
    if (item.min1 >= floor) return;
    item.sum += (floor - item.min1) * @as(i64, @intCast(item.min_count));
    if (item.max1 == item.min1) {
        item.max1 = floor;
    } else if (item.max2 == item.min1) {
        item.max2 = floor;
    }
    item.min1 = floor;
}

fn push(tree: *[TREE_SIZE]Node, node: usize, low: usize, high: usize) void {
    if (high - low == 1) return;
    const middle = low + (high - low) / 2;
    const delta = tree[node].add;
    if (delta != 0) {
        applyAdd(&tree[2 * node], middle - low, delta);
        applyAdd(&tree[2 * node + 1], high - middle, delta);
        tree[node].add = 0;
    }
    const max1 = tree[node].max1;
    if (tree[2 * node].max1 > max1) applyChmin(&tree[2 * node], max1);
    if (tree[2 * node + 1].max1 > max1) applyChmin(&tree[2 * node + 1], max1);
    const min1 = tree[node].min1;
    if (tree[2 * node].min1 < min1) applyChmax(&tree[2 * node], min1);
    if (tree[2 * node + 1].min1 < min1) applyChmax(&tree[2 * node + 1], min1);
}

fn rangeAdd(tree: *[TREE_SIZE]Node, node: usize, low: usize, high: usize, ql: usize, qr: usize, delta: i64) void {
    if (qr <= low or high <= ql or delta == 0) return;
    if (ql <= low and high <= qr) {
        applyAdd(&tree[node], high - low, delta);
        return;
    }
    push(tree, node, low, high);
    const middle = low + (high - low) / 2;
    rangeAdd(tree, 2 * node, low, middle, ql, qr, delta);
    rangeAdd(tree, 2 * node + 1, middle, high, ql, qr, delta);
    pull(tree, node);
}

fn rangeChmin(tree: *[TREE_SIZE]Node, node: usize, low: usize, high: usize, ql: usize, qr: usize, ceiling: i64) void {
    if (qr <= low or high <= ql or tree[node].max1 <= ceiling) return;
    if (ql <= low and high <= qr and tree[node].max2 < ceiling) {
        applyChmin(&tree[node], ceiling);
        return;
    }
    push(tree, node, low, high);
    const middle = low + (high - low) / 2;
    rangeChmin(tree, 2 * node, low, middle, ql, qr, ceiling);
    rangeChmin(tree, 2 * node + 1, middle, high, ql, qr, ceiling);
    pull(tree, node);
}

fn rangeChmax(tree: *[TREE_SIZE]Node, node: usize, low: usize, high: usize, ql: usize, qr: usize, floor: i64) void {
    if (qr <= low or high <= ql or tree[node].min1 >= floor) return;
    if (ql <= low and high <= qr and tree[node].min2 > floor) {
        applyChmax(&tree[node], floor);
        return;
    }
    push(tree, node, low, high);
    const middle = low + (high - low) / 2;
    rangeChmax(tree, 2 * node, low, middle, ql, qr, floor);
    rangeChmax(tree, 2 * node + 1, middle, high, ql, qr, floor);
    pull(tree, node);
}

fn rangeSum(tree: *[TREE_SIZE]Node, node: usize, low: usize, high: usize, ql: usize, qr: usize) i64 {
    if (qr <= low or high <= ql) return 0;
    if (ql <= low and high <= qr) return tree[node].sum;
    push(tree, node, low, high);
    const middle = low + (high - low) / 2;
    return rangeSum(tree, 2 * node, low, middle, ql, qr) + rangeSum(tree, 2 * node + 1, middle, high, ql, qr);
}

export fn segment_tree_beats(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    if (values[0] < 1 or values[0] > @as(i64, @intCast(MAX_ITEMS))) return -1;
    const n: usize = @intCast(values[0]);
    if (length < n + 2 or values[n + 1] < 0 or values[n + 1] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const q: usize = @intCast(values[n + 1]);
    if (length != n + 2 + 4 * q) return -1;
    for (0..n) |i| {
        if (values[i + 1] < -VALUE_LIMIT or values[i + 1] > VALUE_LIMIT) return -1;
    }
    for (0..q) |i| {
        const p = n + 2 + 4 * i;
        const opcode = values[p];
        const left = values[p + 1];
        const right = values[p + 2];
        const argument = values[p + 3];
        if (opcode < 0 or opcode > 3 or left < 0 or left >= right or right > @as(i64, @intCast(n))) return -1;
        if ((opcode == 3 and argument != 0) or (opcode != 3 and (argument < -VALUE_LIMIT or argument > VALUE_LIMIT))) return -1;
    }

    var tree: [TREE_SIZE]Node = undefined;
    build(&tree, values, 1, 1, 0, n);
    var checksum: i64 = 0;
    var ordinal: i64 = 0;
    for (0..q) |i| {
        const p = n + 2 + 4 * i;
        const left: usize = @intCast(values[p + 1]);
        const right: usize = @intCast(values[p + 2]);
        const argument = values[p + 3];
        switch (values[p]) {
            0 => rangeChmin(&tree, 1, 0, n, left, right, argument),
            1 => rangeChmax(&tree, 1, 0, n, left, right, argument),
            2 => rangeAdd(&tree, 1, 0, n, left, right, argument),
            else => {
                ordinal += 1;
                checksum += ordinal * (rangeSum(&tree, 1, 0, n, left, right) + QUERY_OFFSET);
            },
        }
    }
    return checksum;
}
