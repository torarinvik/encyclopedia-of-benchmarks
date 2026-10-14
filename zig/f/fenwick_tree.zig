const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_072_000_001;
const FINAL_OFFSET: i64 = 512_000_001;

fn lowbit(index: usize) usize { return index & (~index + 1); }

fn prefixSum(tree: *const [MAX_ITEMS + 1]i64, end: usize) i64 {
    var index = end;
    var total: i64 = 0;
    while (index > 0) {
        total += tree[index];
        index -= lowbit(index);
    }
    return total;
}

export fn fenwick_tree_benchmark(values: [*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT_VALUES) return -1;
    const item_count_value = values[0];
    const operation_count_value = values[1];
    if (item_count_value < 1 or item_count_value > MAX_ITEMS or
        operation_count_value < 0 or operation_count_value > MAX_OPERATIONS) return -1;
    const item_count: usize = @intCast(item_count_value);
    const operation_count: usize = @intCast(operation_count_value);
    if (length != 2 + 3 * operation_count) return -1;
    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = values[position];
        const first = values[position + 1];
        const second = values[position + 2];
        if (opcode == 0) {
            if (first < 0 or first >= item_count_value or second < -VALUE_LIMIT or second > VALUE_LIMIT) return -1;
        } else if (opcode == 1) {
            if (first < 0 or second < first or second >= item_count_value) return -1;
        } else return -1;
    }

    var data: [MAX_ITEMS]i64 = @splat(0);
    var tree: [MAX_ITEMS + 1]i64 = @splat(0);
    var checksum: i64 = 0;
    for (0..operation_count) |operation| {
        const position = 2 + 3 * operation;
        const opcode = values[position];
        const first: usize = @intCast(values[position + 1]);
        const second = values[position + 2];
        if (opcode == 0) {
            data[first] += second;
            var index = first + 1;
            while (index <= item_count) : (index += lowbit(index)) tree[index] += second;
        } else {
            const right: usize = @intCast(second);
            const result = prefixSum(&tree, right + 1) - prefixSum(&tree, first);
            checksum += @as(i64, @intCast(operation + 1)) * (result + QUERY_OFFSET);
        }
    }
    for (0..item_count) |i| {
        checksum += @as(i64, @intCast(operation_count + i + 1)) * (data[i] + FINAL_OFFSET);
    }
    return checksum;
}
