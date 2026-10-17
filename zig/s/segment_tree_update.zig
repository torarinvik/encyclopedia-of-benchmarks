const MAX_N: usize = 64;
const MAX_OPERATIONS: usize = 64;
const MAX_INPUT_LENGTH: usize = 259;
const MAX_TREE_LENGTH: usize = 128;
const VALUE_MIN: i64 = -1_000_000;
const VALUE_MAX: i64 = 1_000_000;
const FNV_OFFSET: u64 = 14695981039346656037;
const FNV_PRIME: u64 = 1099511628211;
const MASK_63: u64 = 0x7fffffffffffffff;

fn querySum(tree: [*]const i32, node: usize, segment_left: usize, segment_right: usize,
            query_left: usize, query_right: usize) i32 {
    if (query_left <= segment_left and segment_right <= query_right) return tree[node];
    if (query_right < segment_left or segment_right < query_left) return 0;
    const middle = segment_left + (segment_right - segment_left) / 2;
    return querySum(tree, node * 2, segment_left, middle, query_left, query_right)
        + querySum(tree, node * 2 + 1, middle + 1, segment_right, query_left, query_right);
}

fn hashI64Word(hash_value: u64, word: i64) u64 {
    var hash = hash_value;
    const bits: u64 = @bitCast(word);
    for (0..8) |byte| {
        const octet: u64 = @truncate(bits >> @intCast(byte * 8));
        hash = (hash ^ octet) *% FNV_PRIME;
    }
    return hash;
}

export fn segment_tree_update_benchmark(input: [*c]const i64, length: usize) i64 {
    if (input == null or length < 3 or length > MAX_INPUT_LENGTH) return -1;
    const values = input;
    if (values[0] < 1 or values[0] > MAX_N) return -1;
    const n: usize = @intCast(values[0]);
    if (length < n + 2) return -1;
    if (values[n + 1] < 1 or values[n + 1] > MAX_OPERATIONS) return -1;
    const operation_count: usize = @intCast(values[n + 1]);
    if (length != n + 2 + 3 * operation_count) return -1;

    for (0..n) |index| {
        if (values[index + 1] < VALUE_MIN or values[index + 1] > VALUE_MAX) return -1;
    }
    const operations_start = n + 2;
    var query_count: usize = 0;
    for (0..operation_count) |operation| {
        const offset = operations_start + 3 * operation;
        const kind = values[offset];
        const first = values[offset + 1];
        const second = values[offset + 2];
        if (kind == 0) {
            if (first < 0 or first > second or second >= @as(i64, @intCast(n))) return -1;
            query_count += 1;
        } else if (kind == 1) {
            if (first < 0 or first >= @as(i64, @intCast(n)) or second < VALUE_MIN or second > VALUE_MAX) return -1;
        } else {
            return -1;
        }
    }
    if (query_count == 0) return -1;

    var power: usize = 1;
    while (power < n) power *= 2;
    var tree: [MAX_TREE_LENGTH]i32 = [_]i32{0} ** MAX_TREE_LENGTH;
    for (0..n) |index| tree[power + index] = @intCast(values[index + 1]);
    var node = power - 1;
    while (node > 0) : (node -= 1) tree[node] = tree[node * 2] + tree[node * 2 + 1];

    var hash = hashI64Word(FNV_OFFSET, @intCast(query_count));
    for (0..operation_count) |operation| {
        const offset = operations_start + 3 * operation;
        const kind = values[offset];
        const first = values[offset + 1];
        const second = values[offset + 2];
        if (kind == 0) {
            const sum = querySum(&tree[0], 1, 1, power, @as(usize, @intCast(first)) + 1,
                                 @as(usize, @intCast(second)) + 1);
            hash = hashI64Word(hash, sum);
        } else {
            var leaf = power + @as(usize, @intCast(first));
            tree[leaf] = @intCast(second);
            while (leaf > 1) {
                leaf /= 2;
                tree[leaf] = tree[leaf * 2] + tree[leaf * 2 + 1];
            }
        }
    }
    return @intCast(hash & MASK_63);
}
