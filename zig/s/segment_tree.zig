const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = MAX_ITEMS + 3 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 256_000_001;
const FINAL_OFFSET: i64 = 1_000_001;

fn identity(mode: i64) i64 {
    if (mode == 1) return VALUE_LIMIT + 1;
    if (mode == 2) return -(VALUE_LIMIT + 1);
    return 0;
}

fn combine(mode: i64, left: i64, right: i64) i64 {
    if (mode == 1) return @min(left, right);
    if (mode == 2) return @max(left, right);
    return left + right;
}

export fn segment_tree_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 3 or length > MAX_INPUT_VALUES) return -1;
    const mode = values[0];
    const item_count_value = values[1];
    if (mode < 0 or mode > 2 or item_count_value < 1 or item_count_value > MAX_ITEMS) return -1;
    const item_count: usize = @intCast(item_count_value);
    if (length < item_count + 3) return -1;
    const operation_count_value = values[item_count + 2];
    if (operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(operation_count_value);
    if (length != item_count + 3 + 3 * operation_count) return -1;

    var data: [MAX_ITEMS]i64 = undefined;
    for (0..item_count) |i| {
        const value = values[i + 2];
        if (value < -VALUE_LIMIT or value > VALUE_LIMIT) return -1;
        data[i] = value;
    }
    for (0..operation_count) |operation| {
        const position = item_count + 3 + 3 * operation;
        const opcode = values[position];
        const first = values[position + 1];
        const second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 or first >= item_count_value or second < -VALUE_LIMIT or second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 or second < first or second >= item_count_value) return -1;
        } else return -1;
    }

    var base: usize = 1;
    while (base < item_count) : (base *= 2) {}
    const empty = identity(mode);
    var tree: [2 * MAX_ITEMS]i64 = undefined;
    for (0..2 * base) |i| tree[i] = empty;
    for (0..item_count) |i| tree[base + i] = data[i];
    var node = base;
    while (node > 1) {
        node -= 1;
        tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
    }

    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const position = item_count + 3 + 3 * operation;
        const opcode = values[position];
        const first: usize = @intCast(values[position + 1]);
        if (opcode == 0) {
            const value = values[position + 2];
            data[first] = value;
            node = base + first;
            tree[node] = value;
            while (node > 1) {
                node /= 2;
                tree[node] = combine(mode, tree[2 * node], tree[2 * node + 1]);
            }
        } else {
            var left = base + first;
            var right: usize = base + @as(usize, @intCast(values[position + 2])) + 1;
            var result = empty;
            while (left < right) {
                if (left & 1 == 1) { result = combine(mode, result, tree[left]); left += 1; }
                if (right & 1 == 1) { right -= 1; result = combine(mode, result, tree[right]); }
                left /= 2;
                right /= 2;
            }
            checksum += @as(i64, @intCast(operation + 1)) * (result + QUERY_OFFSET);
        }
    }
    for (0..item_count) |i| {
        checksum += @as(i64, @intCast(operation_count + i + 1)) * (data[i] + FINAL_OFFSET);
    }
    return checksum;
}
