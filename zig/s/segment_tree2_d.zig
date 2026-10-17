const MAX_ROWS: usize = 16;
const MAX_COLUMNS: usize = 16;
const MAX_OPERATIONS: usize = 256;
const MAX_TREE_SIDE: usize = 64;
const MAX_VALID_INPUT_LENGTH: usize = 1283;
const MAX_PARSEABLE_INPUT_LENGTH: usize = 1284;
const CHECKSUM_OFFSET: i64 = 256001;

fn setColumn(tree: *[MAX_TREE_SIDE][MAX_TREE_SIDE]i64, row_node: usize,
    column_base: usize, column: usize, value: i64) void {
    var node = column_base + column;
    tree[row_node][node] = value;
    node >>= 1;
    while (node > 0) : (node >>= 1) {
        tree[row_node][node] = tree[row_node][node << 1] + tree[row_node][(node << 1) | 1];
    }
}

fn queryColumns(tree: *const [MAX_TREE_SIDE][MAX_TREE_SIDE]i64, row_node: usize,
    column_base: usize, left: usize, right: usize) i64 {
    var first = left + column_base;
    var last = right + column_base;
    var sum: i64 = 0;
    while (first < last) {
        if ((first & 1) != 0) { sum += tree[row_node][first]; first += 1; }
        if ((last & 1) != 0) { last -= 1; sum += tree[row_node][last]; }
        first >>= 1;
        last >>= 1;
    }
    return sum;
}

fn assignPoint(tree: *[MAX_TREE_SIDE][MAX_TREE_SIDE]i64, row_base: usize,
    column_base: usize, row: usize, column: usize, value: i64) void {
    const row_leaf = row_base + row;
    setColumn(tree, row_leaf, column_base, column, value);
    var row_node = row_leaf >> 1;
    while (row_node > 0) : (row_node >>= 1) {
        const left_value = tree[row_node << 1][column_base + column];
        const right_value = tree[(row_node << 1) | 1][column_base + column];
        setColumn(tree, row_node, column_base, column, left_value + right_value);
    }
}

fn queryRectangle(tree: *const [MAX_TREE_SIDE][MAX_TREE_SIDE]i64, row_base: usize,
    column_base: usize, top: usize, bottom: usize, left: usize, right: usize) i64 {
    var first = top + row_base;
    var last = bottom + row_base;
    var sum: i64 = 0;
    while (first < last) {
        if ((first & 1) != 0) { sum += queryColumns(tree, first, column_base, left, right); first += 1; }
        if ((last & 1) != 0) { last -= 1; sum += queryColumns(tree, last, column_base, left, right); }
        first >>= 1;
        last >>= 1;
    }
    return sum;
}

export fn segment_tree2_d_benchmark(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 3 or length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_ROWS)) or input[1] < 1 or input[1] > @as(i64, @intCast(MAX_COLUMNS))) return -1;
    if (input[2] < 0 or input[2] > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const rows: usize = @intCast(input[0]);
    const columns: usize = @intCast(input[1]);
    const rows_i64 = input[0];
    const columns_i64 = input[1];
    const operation_count: usize = @intCast(input[2]);
    if (length != 3 + 5 * operation_count or length > MAX_VALID_INPUT_LENGTH) return -1;

    var row_base: usize = 1;
    while (row_base < rows) : (row_base <<= 1) {}
    var column_base: usize = 1;
    while (column_base < columns) : (column_base <<= 1) {}
    var tree: [MAX_TREE_SIDE][MAX_TREE_SIDE]i64 = @splat(@splat(0));
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const offset = 3 + 5 * operation;
        const opcode = input[offset];
        const first = input[offset + 1];
        const second = input[offset + 2];
        const third = input[offset + 3];
        const fourth = input[offset + 4];
        if (opcode == 0) {
            if (first < 0 or first >= rows_i64 or second < 0 or second >= columns_i64 or third < -1000 or third > 1000 or fourth != 0) return -1;
            assignPoint(&tree, row_base, column_base, @intCast(first), @intCast(second), third);
        } else if (opcode == 1) {
            if (first < 0 or first > second or second > rows_i64 or third < 0 or third > fourth or fourth > columns_i64) return -1;
            const result = queryRectangle(&tree, row_base, column_base, @intCast(first), @intCast(second), @intCast(third), @intCast(fourth));
            checksum += (@as(i64, @intCast(operation)) + 1) * (result + CHECKSUM_OFFSET);
        } else return -1;
    }
    return checksum;
}
