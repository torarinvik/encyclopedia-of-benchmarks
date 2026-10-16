const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 322;
const NODE_CAP: usize = 640;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

const Node = struct { sum: i64, left: i32, right: i32 };

fn makeNode(nodes: *[NODE_CAP]Node, used: *usize, sum: i64, left: i32, right: i32) i32 {
    if (used.* >= NODE_CAP) return -1;
    const index: i32 = @intCast(used.*);
    nodes[used.*] = .{ .sum = sum, .left = left, .right = right };
    used.* += 1;
    return index;
}
fn build(nodes: *[NODE_CAP]Node, used: *usize, values: [*]const i64, left: usize, right: usize) i32 {
    if (left == right) return makeNode(nodes, used, values[left], -1, -1);
    const mid = left + (right - left) / 2;
    const a = build(nodes, used, values, left, mid);
    const b = build(nodes, used, values, mid + 1, right);
    if (a < 0 or b < 0) return -1;
    return makeNode(nodes, used, nodes[@intCast(a)].sum + nodes[@intCast(b)].sum, a, b);
}
fn pointSet(nodes: *[NODE_CAP]Node, used: *usize, root: i32, left: usize, right: usize, index: usize, value: i64) i32 {
    if (left == right) return makeNode(nodes, used, value, -1, -1);
    const mid = left + (right - left) / 2;
    var a = nodes[@intCast(root)].left;
    var b = nodes[@intCast(root)].right;
    if (index <= mid) a = pointSet(nodes, used, a, left, mid, index, value)
    else b = pointSet(nodes, used, b, mid + 1, right, index, value);
    if (a < 0 or b < 0) return -1;
    return makeNode(nodes, used, nodes[@intCast(a)].sum + nodes[@intCast(b)].sum, a, b);
}
fn rangeSum(nodes: *const [NODE_CAP]Node, node: i32, left: usize, right: usize, ql: usize, qr: usize) i64 {
    if (ql <= left and right <= qr) return nodes[@intCast(node)].sum;
    const mid = left + (right - left) / 2;
    var total: i64 = 0;
    if (ql <= mid) total += rangeSum(nodes, nodes[@intCast(node)].left, left, mid, ql, qr);
    if (qr > mid) total += rangeSum(nodes, nodes[@intCast(node)].right, mid + 1, right, ql, qr);
    return total;
}
fn hashWord(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    return result;
}

export fn persistent_segment_tree(input: ?[*]const i64, length: usize) i64 {
    if (input == null) return -1;
    const values = input.?;
    if (length < 3 or length > MAX_INPUT) return -1;
    const n64 = values[0]; const q64 = values[1];
    if (n64 < 1 or n64 > MAX_N or q64 < 0 or q64 > MAX_Q) return -1;
    const n: usize = @intCast(n64); const q: usize = @intCast(q64);
    if (length != 2 + n + 4 * q) return -1;
    for (0..n) |i| if (values[2 + i] < -1000 or values[2 + i] > 1000) return -1;
    var nodes: [NODE_CAP]Node = undefined;
    var used: usize = 0;
    var roots: [MAX_Q + 1]i32 = undefined;
    roots[0] = build(&nodes, &used, values + 2, 0, n - 1);
    if (roots[0] < 0) return -1;
    var version_count: usize = 1;
    var query_count: usize = 0;
    var query_sums: [MAX_Q]i64 = undefined;
    var offset = 2 + n;
    for (0..q) |_| {
        const op = values[offset]; const a = values[offset + 1]; const b = values[offset + 2]; const c = values[offset + 3];
        offset += 4;
        if (op == 0) {
            if (a < 0 or a >= @as(i64, @intCast(version_count)) or b < 0 or b >= n64 or c < -1000 or c > 1000) return -1;
            const next = pointSet(&nodes, &used, roots[@intCast(a)], 0, n - 1, @intCast(b), c);
            if (next < 0) return -1;
            roots[version_count] = next; version_count += 1;
        } else if (op == 1) {
            if (a < 0 or a >= @as(i64, @intCast(version_count)) or b < 0 or c < b or c >= n64) return -1;
            query_sums[query_count] = rangeSum(&nodes, roots[@intCast(a)], 0, n - 1, @intCast(b), @intCast(c));
            query_count += 1;
        } else return -1;
    }
    var hash = hashWord(FNV_OFFSET, @intCast(version_count));
    hash = hashWord(hash, @intCast(query_count));
    for (0..query_count) |i| hash = hashWord(hash, query_sums[i]);
    return @intCast(hash & 0x7fffffffffffffff);
}
