const MAX_N: usize = 64;
const MAX_Q: usize = 64;
const MAX_INPUT_LENGTH: usize = 2 + MAX_N + 4 * MAX_Q + 1;
const NODE_CAP: usize = 16384;
const FNV_OFFSET: u64 = 0xcbf29ce484222325;
const FNV_PRIME: u64 = 0x100000001b3;

const Node = struct { sum: i64, prop: i64, left: i32, right: i32 };

fn makeNode(nodes: *[NODE_CAP]Node, used: *usize, sum: i64, prop: i64, left: i32, right: i32) i32 {
    if (used.* >= NODE_CAP) return -1;
    const index: i32 = @intCast(used.*);
    nodes[used.*] = .{ .sum = sum, .prop = prop, .left = left, .right = right };
    used.* += 1;
    return index;
}

fn cloneNode(nodes: *[NODE_CAP]Node, used: *usize, source: i32) i32 {
    if (source < 0 or used.* >= NODE_CAP) return -1;
    const index: i32 = @intCast(used.*);
    nodes[used.*] = nodes[@intCast(source)];
    used.* += 1;
    return index;
}

fn pushLazy(nodes: *[NODE_CAP]Node, used: *usize, node: i32, left: usize, right: usize) bool {
    const prop = nodes[@intCast(node)].prop;
    if (prop == 0) return true;
    nodes[@intCast(node)].sum += @as(i64, @intCast(right - left + 1)) * prop;
    if (left != right) {
        const new_left = cloneNode(nodes, used, nodes[@intCast(node)].left);
        const new_right = cloneNode(nodes, used, nodes[@intCast(node)].right);
        if (new_left < 0 or new_right < 0) return false;
        nodes[@intCast(node)].left = new_left;
        nodes[@intCast(node)].right = new_right;
        nodes[@intCast(new_left)].prop += prop;
        nodes[@intCast(new_right)].prop += prop;
    }
    nodes[@intCast(node)].prop = 0;
    return true;
}

fn build(nodes: *[NODE_CAP]Node, used: *usize, values: [*]const i64, left: usize, right: usize) i32 {
    if (left == right) return makeNode(nodes, used, values[left], 0, -1, -1);
    const mid = left + (right - left) / 2;
    const a = build(nodes, used, values, left, mid);
    const b = build(nodes, used, values, mid + 1, right);
    if (a < 0 or b < 0) return -1;
    return makeNode(nodes, used, nodes[@intCast(a)].sum + nodes[@intCast(b)].sum, 0, a, b);
}

fn update(nodes: *[NODE_CAP]Node, used: *usize, current: i32, left: usize, right: usize,
           ql: usize, qr: usize, delta: i64) i32 {
    if (!pushLazy(nodes, used, current, left, right)) return -1;
    if (left >= ql and right <= qr) {
        const copy = cloneNode(nodes, used, current);
        if (copy < 0) return -1;
        nodes[@intCast(copy)].prop += delta;
        if (!pushLazy(nodes, used, copy, left, right)) return -1;
        return copy;
    }
    if (left > qr or right < ql) return current;
    const copy = makeNode(nodes, used, 0, 0, -1, -1);
    if (copy < 0) return -1;
    const mid = left + (right - left) / 2;
    const a = update(nodes, used, nodes[@intCast(current)].left, left, mid, ql, qr, delta);
    const b = update(nodes, used, nodes[@intCast(current)].right, mid + 1, right, ql, qr, delta);
    if (a < 0 or b < 0) return -1;
    nodes[@intCast(copy)].left = a;
    nodes[@intCast(copy)].right = b;
    nodes[@intCast(copy)].sum = nodes[@intCast(a)].sum + nodes[@intCast(b)].sum;
    return copy;
}

fn query(nodes: *[NODE_CAP]Node, used: *usize, node: i32, left: usize, right: usize,
         ql: usize, qr: usize) ?i64 {
    if (!pushLazy(nodes, used, node, left, right)) return null;
    if (right < ql or qr < left) return 0;
    if (ql <= left and right <= qr) return nodes[@intCast(node)].sum;
    const mid = left + (right - left) / 2;
    const a = query(nodes, used, nodes[@intCast(node)].left, left, mid, ql, qr) orelse return null;
    const b = query(nodes, used, nodes[@intCast(node)].right, mid + 1, right, ql, qr) orelse return null;
    return a + b;
}

fn hashWord(hash: u64, value: i64) u64 {
    var result = hash;
    const bits: u64 = @bitCast(value);
    for (0..8) |byte_index| result = (result ^ @as(u64, @truncate(bits >> @intCast(byte_index * 8)))) *% FNV_PRIME;
    return result;
}

fn execute(input: []const i64) ?i64 {
    if (input.len < 2 or input.len > MAX_INPUT_LENGTH) return null;
    const n64 = input[0];
    const q64 = input[1];
    if (n64 < 1 or n64 > @as(i64, MAX_N) or q64 < 0 or q64 > @as(i64, MAX_Q)) return null;
    const n: usize = @intCast(n64);
    const q: usize = @intCast(q64);
    if (input.len != 2 + n + 4 * q) return null;
    for (input[2 .. 2 + n]) |value| if (value < -1000 or value > 1000) return null;

    var nodes: [NODE_CAP]Node = undefined;
    var used: usize = 0;
    var roots: [MAX_Q + 1]i32 = undefined;
    roots[0] = build(&nodes, &used, input.ptr + 2, 0, n - 1);
    if (roots[0] < 0) return null;
    var version_count: usize = 1;
    var query_count: usize = 0;
    var query_sums: [MAX_Q]i64 = undefined;
    var offset = 2 + n;

    for (0..q) |_| {
        const op = input[offset];
        const a = input[offset + 1];
        const b = input[offset + 2];
        const c = input[offset + 3];
        offset += 4;
        if (op == 0) {
            if (a < 0 or a > b or b >= n64 or c < -1000 or c > 1000) return null;
            const next = update(&nodes, &used, roots[version_count - 1], 0, n - 1,
                                @intCast(a), @intCast(b), c);
            if (next < 0) return null;
            roots[version_count] = next;
            version_count += 1;
        } else if (op == 1) {
            if (a < 0 or a >= @as(i64, @intCast(version_count)) or b < 0 or c < b or c >= n64) return null;
            query_sums[query_count] = query(&nodes, &used, roots[@intCast(a)],
                                            0, n - 1, @intCast(b), @intCast(c)) orelse return null;
            query_count += 1;
        } else return null;
    }

    var hash = hashWord(FNV_OFFSET, @intCast(version_count));
    hash = hashWord(hash, @intCast(query_count));
    for (0..query_count) |index| hash = hashWord(hash, query_sums[index]);
    return @intCast(hash & 0x7fff_ffff_ffff_ffff);
}

export fn persistent_seg_tree_lazy_prop(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 2 or length > MAX_INPUT_LENGTH) return -1;
    return execute(input[0..length]) orelse -1;
}
