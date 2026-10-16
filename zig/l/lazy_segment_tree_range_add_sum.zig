const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_LENGTH: usize = 2306;
const TREE_SIZE: usize = 2 * MAX_ITEMS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_328_000_001;

fn apply(tree: *[TREE_SIZE]i64, pending: *[TREE_SIZE]i64,
    node: usize, segment_length: usize, delta: i64) void {
    tree[node] += delta * @as(i64, @intCast(segment_length));
    pending[node] += delta;
}

fn push(tree: *[TREE_SIZE]i64, pending: *[TREE_SIZE]i64,
    node: usize, segment_length: usize) void {
    if (segment_length > 1 and pending[node] != 0) {
        const child_length = segment_length / 2;
        apply(tree, pending, 2 * node, child_length, pending[node]);
        apply(tree, pending, 2 * node + 1, child_length, pending[node]);
        pending[node] = 0;
    }
}

fn rangeAdd(tree: *[TREE_SIZE]i64, pending: *[TREE_SIZE]i64,
    node: usize, low: usize, high: usize, query_low: usize,
    query_high: usize, delta: i64) void {
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

fn rangeSum(tree: *[TREE_SIZE]i64, pending: *[TREE_SIZE]i64,
    node: usize, low: usize, high: usize, query_low: usize, query_high: usize) i64 {
    if (query_low <= low and high <= query_high) return tree[node];
    push(tree, pending, node, high - low);
    const middle = (low + high) / 2;
    var result: i64 = 0;
    if (query_low < middle) result += rangeSum(tree, pending, 2 * node, low, middle, query_low, query_high);
    if (query_high > middle) result += rangeSum(tree, pending, 2 * node + 1, middle, high, query_low, query_high);
    return result;
}

export fn lazy_segment_tree_range_add_sum(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const item_count_value = values[0];
    if (item_count_value < 1 or item_count_value > MAX_ITEMS) return -1;
    const item_count: usize = @intCast(item_count_value);
    if (length < item_count + 2) return -1;
    const operation_count_value = values[item_count + 1];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != item_count + 2 + 4 * operation_count) return -1;

    for (0..item_count) |index| {
        if (values[index + 1] < -VALUE_LIMIT or values[index + 1] > VALUE_LIMIT) return -1;
    }
    for (0..operation_count) |operation| {
        const position = item_count + 2 + 4 * operation;
        const opcode = values[position];
        const left = values[position + 1];
        const right = values[position + 2];
        const delta = values[position + 3];
        if (left < 0 or left >= right or right > item_count_value) return -1;
        if (opcode == 0) {
            if (delta < -VALUE_LIMIT or delta > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (delta != 0) return -1;
        } else return -1;
    }

    var base: usize = 1;
    while (base < item_count) base *= 2;
    var tree: [TREE_SIZE]i64 = @splat(0);
    var pending: [TREE_SIZE]i64 = @splat(0);
    for (0..item_count) |index| tree[base + index] = values[index + 1];
    var node = base;
    while (node > 1) {
        node -= 1;
        tree[node] = tree[2 * node] + tree[2 * node + 1];
    }

    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const position = item_count + 2 + 4 * operation;
        const left: usize = @intCast(values[position + 1]);
        const right: usize = @intCast(values[position + 2]);
        if (values[position] == 0) {
            rangeAdd(&tree, &pending, 1, 0, base, left, right, values[position + 3]);
        } else {
            checksum += rangeSum(&tree, &pending, 1, 0, base, left, right) + QUERY_OFFSET;
        }
    }
    return checksum;
}
