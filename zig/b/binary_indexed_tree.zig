const MAX_ITEMS: usize = 256;
const MAX_OPERATIONS: usize = 512;
const MAX_INPUT_VALUES: usize = 2 + 3 * MAX_OPERATIONS;
const VALUE_LIMIT: i64 = 1_000_000;
const QUERY_OFFSET: i64 = 131_072_000_001;
const FINAL_OFFSET: i64 = 512_000_001;

fn lowbit(index: usize) usize { return index & (~index + 1); }
fn prefixSum(tree: *const [MAX_ITEMS + 2]i32, initial: usize) i32 {
    var count = initial;
    var sum: i32 = 0;
    while (count > 0) { sum += tree[count]; count -= lowbit(count); }
    return sum;
}

export fn binary_indexed_tree(values: [*c]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > MAX_INPUT_VALUES) return -1;
    const n_value = values[0];
    const op_value = values[1];
    if (n_value < 2 or n_value > @as(i64, @intCast(MAX_ITEMS)) or (n_value & (n_value - 1)) != 0 or op_value < 0 or op_value > @as(i64, @intCast(MAX_OPERATIONS))) return -1;
    const n: usize = @intCast(n_value);
    const operations: usize = @intCast(op_value);
    if (length != 2 + 3 * operations) return -1;
    for (0..operations) |op| {
        const at = 2 + 3 * op;
        const code = values[at];
        const first = values[at + 1];
        const second = values[at + 2];
        if (code == 0) {
            if (first < 0 or first >= n_value or second < -VALUE_LIMIT or second > VALUE_LIMIT) return -1;
        } else if (code == 1) {
            if (first < 0 or second < first or second >= n_value) return -1;
        } else return -1;
    }
    var data = [_]i32{0} ** MAX_ITEMS;
    var tree = [_]i32{0} ** (MAX_ITEMS + 2);
    var checksum: i64 = 0;
    for (0..operations) |op| {
        const at = 2 + 3 * op;
        const code = values[at];
        const first: usize = @intCast(values[at + 1]);
        const second = values[at + 2];
        if (code == 0) {
            const delta: i32 = @intCast(second);
            data[first] += delta;
            var start = first + 1;
            while (start <= n + 1) { tree[start] += delta; start += lowbit(start); }
        } else {
            const result = prefixSum(&tree, @intCast(second + 1)) - prefixSum(&tree, first);
            checksum += @as(i64, @intCast(op + 1)) * (@as(i64, result) + QUERY_OFFSET);
        }
    }
    for (0..n) |i| checksum += @as(i64, @intCast(operations + i + 1)) * (@as(i64, data[i]) + FINAL_OFFSET);
    return checksum;
}
