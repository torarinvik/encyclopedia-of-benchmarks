const DOMAIN: i64 = 64;
const MAX_Q: usize = 32;
const MAX_ROOTS: usize = 33;
const MAX_NODES: usize = 1024;
const MAX_INPUT: usize = 131;
const MAX_OUTPUT: usize = 256;

const Node = struct { left: i32 = 0, right: i32 = 0, total: i64 = 0 };
const Operation = struct { op: i64 = 0, a: i64 = 0, b: i64 = 0, c: i64 = 0 };
const SplitParts = struct { remain: i32, moved: i32 };

fn newNode(nodes: *[MAX_NODES]Node, used: *usize) i32 {
    if (used.* >= MAX_NODES) return -1;
    const node = used.*;
    used.* += 1;
    nodes[node] = .{};
    return @intCast(node);
}

fn insert(nodes: *[MAX_NODES]Node, used: *usize, node_value: i32,
    lo: i32, hi: i32, value: i32, amount: i64) i32 {
    var node = node_value;
    if (node == 0) {
        node = newNode(nodes, used);
        if (node < 0) return -1;
    }
    const index: usize = @intCast(node);
    if (lo == hi) {
        nodes[index].total += amount;
        return node;
    }
    const mid = @divTrunc(lo + hi, 2);
    if (value <= mid) {
        const child = insert(nodes, used, nodes[index].left, lo, mid, value, amount);
        if (child < 0) return -1;
        nodes[index].left = child;
    } else {
        const child = insert(nodes, used, nodes[index].right, mid + 1, hi, value, amount);
        if (child < 0) return -1;
        nodes[index].right = child;
    }
    const left_index: usize = @intCast(nodes[index].left);
    const right_index: usize = @intCast(nodes[index].right);
    nodes[index].total = nodes[left_index].total + nodes[right_index].total;
    return node;
}

fn mergeNodes(nodes: *[MAX_NODES]Node, a: i32, b: i32, lo: i32, hi: i32) i32 {
    if (a == 0) return b;
    if (b == 0) return a;
    const ai: usize = @intCast(a);
    const bi: usize = @intCast(b);
    if (lo == hi) {
        nodes[ai].total += nodes[bi].total;
        return a;
    }
    const mid = @divTrunc(lo + hi, 2);
    const al = nodes[ai].left;
    const ar = nodes[ai].right;
    const bl = nodes[bi].left;
    const br = nodes[bi].right;
    nodes[ai].left = mergeNodes(nodes, al, bl, lo, mid);
    nodes[ai].right = mergeNodes(nodes, ar, br, mid + 1, hi);
    const left_index: usize = @intCast(nodes[ai].left);
    const right_index: usize = @intCast(nodes[ai].right);
    nodes[ai].total = nodes[left_index].total + nodes[right_index].total;
    return a;
}

fn split(nodes: *[MAX_NODES]Node, used: *usize, node: i32,
    lo: i32, hi: i32, ql: i32, qr: i32) SplitParts {
    if (node == 0 or qr < lo or hi < ql) return .{ .remain = node, .moved = 0 };
    if (ql <= lo and hi <= qr) return .{ .remain = 0, .moved = node };
    const index: usize = @intCast(node);
    const mid = @divTrunc(lo + hi, 2);
    const left_parts = split(nodes, used, nodes[index].left, lo, mid, ql, qr);
    if (left_parts.remain < 0) return .{ .remain = -1, .moved = 0 };
    const right_parts = split(nodes, used, nodes[index].right, mid + 1, hi, ql, qr);
    if (right_parts.remain < 0) return .{ .remain = -1, .moved = 0 };
    nodes[index].left = left_parts.remain;
    nodes[index].right = right_parts.remain;
    const remain_left: usize = @intCast(left_parts.remain);
    const remain_right: usize = @intCast(right_parts.remain);
    nodes[index].total = nodes[remain_left].total + nodes[remain_right].total;
    var moved: i32 = 0;
    if (left_parts.moved != 0 or right_parts.moved != 0) {
        moved = newNode(nodes, used);
        if (moved < 0) return .{ .remain = -1, .moved = 0 };
        const moved_index: usize = @intCast(moved);
        nodes[moved_index].left = left_parts.moved;
        nodes[moved_index].right = right_parts.moved;
        const moved_left: usize = @intCast(left_parts.moved);
        const moved_right: usize = @intCast(right_parts.moved);
        nodes[moved_index].total = nodes[moved_left].total + nodes[moved_right].total;
    }
    return .{ .remain = node, .moved = moved };
}

fn rangeSum(nodes: *const [MAX_NODES]Node, node: i32,
    lo: i32, hi: i32, ql: i32, qr: i32) i64 {
    if (node == 0 or qr < lo or hi < ql) return 0;
    const index: usize = @intCast(node);
    if (ql <= lo and hi <= qr) return nodes[index].total;
    const mid = @divTrunc(lo + hi, 2);
    return rangeSum(nodes, nodes[index].left, lo, mid, ql, qr) +
        rangeSum(nodes, nodes[index].right, mid + 1, hi, ql, qr);
}

fn kth(nodes: *const [MAX_NODES]Node, node: i32,
    lo: i32, hi: i32, k: i64) i64 {
    if (node == 0) return -1;
    const index: usize = @intCast(node);
    if (k > nodes[index].total) return -1;
    if (lo == hi) return @intCast(lo);
    const mid = @divTrunc(lo + hi, 2);
    const left_node = nodes[index].left;
    const left_index: usize = @intCast(left_node);
    if (k <= nodes[left_index].total) return kth(nodes, left_node, lo, mid, k);
    return kth(nodes, nodes[index].right, mid + 1, hi, k - nodes[left_index].total);
}

fn putI64(output: *[MAX_OUTPUT]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn segment_tree_merge_split(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] != DOMAIN or input[1] < 0 or input[1] > MAX_Q) return -1;
    const q: usize = @intCast(input[1]);
    if (length != 2 + 4 * q) return -1;
    var operations = [_]Operation{.{}} ** MAX_Q;
    var roots_count: usize = 1;
    for (0..q) |i| {
        const base = 2 + 4 * i;
        const op = input[base];
        const a = input[base + 1];
        const b = input[base + 2];
        const c = input[base + 3];
        const roots_count_i64: i64 = @intCast(roots_count);
        const a_ok = a >= 0 and a < roots_count_i64;
        const b_ok = b >= 0 and b < roots_count_i64;
        var valid = false;
        if (op == 0) {
            valid = a_ok and b >= 1 and b <= DOMAIN and c >= 1 and c <= 10;
        } else if (op == 1) {
            valid = a_ok and b >= 1 and b <= c and c <= DOMAIN and roots_count < MAX_ROOTS;
            if (valid) roots_count += 1;
        } else if (op == 2) {
            valid = a_ok and b_ok and a != b and c == 0;
        } else if (op == 3) {
            valid = a_ok and b >= 1 and b <= c and c <= DOMAIN;
        } else if (op == 4) {
            valid = a_ok and b >= 1 and b <= 320 and c == 0;
        }
        if (!valid) return -1;
        operations[i] = .{ .op = op, .a = a, .b = b, .c = c };
    }

    var nodes = [_]Node{.{}} ** MAX_NODES;
    var roots = [_]i32{0} ** MAX_ROOTS;
    var staged = [_]u8{0} ** MAX_OUTPUT;
    var used: usize = 1;
    var root_count: usize = 1;
    var byte_count: usize = 0;
    for (0..q) |i| {
        const item = operations[i];
        const a: usize = @intCast(item.a);
        const b: i32 = @intCast(item.b);
        const c: i32 = @intCast(item.c);
        if (item.op == 0) {
            const updated = insert(&nodes, &used, roots[a], 1, 64, b, item.c);
            if (updated < 0) return -1;
            roots[a] = updated;
        } else if (item.op == 1) {
            const parts = split(&nodes, &used, roots[a], 1, 64, b, c);
            if (parts.remain < 0 or parts.moved < 0) return -1;
            roots[a] = parts.remain;
            roots[root_count] = parts.moved;
            root_count += 1;
        } else if (item.op == 2) {
            const source: usize = @intCast(item.b);
            roots[a] = mergeNodes(&nodes, roots[a], roots[source], 1, 64);
            roots[source] = 0;
        } else if (item.op == 3) {
            putI64(&staged, byte_count, rangeSum(&nodes, roots[a], 1, 64, b, c));
            byte_count += 8;
        } else {
            putI64(&staged, byte_count, kth(&nodes, roots[a], 1, 64, item.b));
            byte_count += 8;
        }
    }
    if (output_opt == null or capacity < byte_count) return -2;
    const output = output_opt.?;
    for (0..byte_count) |i| output[i] = staged[i];
    return @intCast(byte_count);
}
