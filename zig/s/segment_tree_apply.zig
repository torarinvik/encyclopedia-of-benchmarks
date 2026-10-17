const MAX_LENGTH: usize = 64;
const MAX_OPERATIONS: usize = 20;
const MAX_TREE_NODES: usize = 128;
const MAX_VALID_INPUT_LENGTH: usize = 146;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 147;
const CHECKSUM_OFFSET: i64 = 67108865;

fn applyUpdate(tree: *[MAX_TREE_NODES]i64, operand: *[MAX_TREE_NODES]i64,
    query_left: usize, query_right: usize, node: usize, left: usize, right: usize, factor: i64) void {
    if (query_left <= left and right <= query_right) {
        operand[node] *= factor;
        tree[node] *= factor;
        return;
    }
    if (query_right <= left or right <= query_left) return;
    const middle = left + (right - left) / 2;
    applyUpdate(tree, operand, query_left, query_right, node * 2, left, middle, factor);
    applyUpdate(tree, operand, query_left, query_right, node * 2 + 1, middle, right, factor);
    tree[node] = operand[node] * (tree[node * 2] + tree[node * 2 + 1]);
}

fn querySum(tree: *const [MAX_TREE_NODES]i64, operand: *const [MAX_TREE_NODES]i64,
    query_left: usize, query_right: usize, node: usize, left: usize, right: usize) i64 {
    if (query_left <= left and right <= query_right) return tree[node];
    if (query_right <= left or right <= query_left) return 0;
    const middle = left + (right - left) / 2;
    return operand[node] * (querySum(tree, operand, query_left, query_right, node * 2, left, middle) +
        querySum(tree, operand, query_left, query_right, node * 2 + 1, middle, right));
}

export fn segment_tree_apply_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_LENGTH))) return -1;
    const n: usize = @intCast(input[0]);
    if (length < n + 2) return -1;
    if (input[n + 1] < 0 or input[n + 1] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const operation_count: usize = @intCast(input[n + 1]);
    if (length != n + 2 + 4 * operation_count or length > MAX_VALID_INPUT_LENGTH) return -1;

    var base: usize = 1;
    while (base < n) : (base <<= 1) {}
    var tree: [MAX_TREE_NODES]i64 = @splat(0);
    var operand: [MAX_TREE_NODES]i64 = @splat(1);
    for (0..n) |index| {
        const value = input[index + 1];
        if (value < -1 or value > 1) return -1;
        tree[base + index] = value;
    }
    var node = base;
    while (node > 1) {
        node -= 1;
        tree[node] = tree[node * 2] + tree[node * 2 + 1];
    }

    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const offset = n + 2 + 4 * operation;
        const opcode = input[offset];
        const left = input[offset + 1];
        const right = input[offset + 2];
        const argument = input[offset + 3];
        if (left < 0 or left > right or right >= @as(i64, @intCast(n))) return -1;
        const query_left: usize = @intCast(left);
        const query_right: usize = @intCast(right + 1);
        if (opcode == 0) {
            if (argument < -2 or argument > 2) return -1;
            applyUpdate(&tree, &operand, query_left, query_right, 1, 0, base, argument);
        } else if (opcode == 1) {
            if (argument != 0) return -1;
            const result = querySum(&tree, &operand, query_left, query_right, 1, 0, base);
            checksum += (@as(i64, @intCast(operation)) + 1) * (result + CHECKSUM_OFFSET);
        } else return -1;
    }
    return checksum;
}
