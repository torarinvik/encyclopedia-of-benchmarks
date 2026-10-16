const std = @import("std");
const MAX_N: usize = 256;
const MAX_Q: usize = 512;
const MAX_INPUT: usize = 2306;
const CHECKSUM_OFFSET: i64 = 1_000_001;

fn build(node: usize, left: usize, right: usize, values: []const i64, tree: []i64) void {
    if (left == right) { tree[node] = values[left]; return; }
    const mid = left + (right - left) / 2;
    build(node * 2, left, mid, values, tree);
    build(node * 2 + 1, mid + 1, right, values, tree);
    tree[node] = @max(tree[node * 2], tree[node * 2 + 1]);
}

fn push(node: usize, left: usize, right: usize, tree: []i64, lazy: []i64, pending: []bool) void {
    if (!pending[node]) return;
    tree[node] = lazy[node];
    pending[node] = false;
    if (left != right) {
        const child = node * 2;
        lazy[child] = tree[node]; lazy[child + 1] = tree[node];
        pending[child] = true; pending[child + 1] = true;
    }
}

fn assignRange(node: usize, left: usize, right: usize, ql: usize, qr: usize, value: i64,
               tree: []i64, lazy: []i64, pending: []bool) void {
    push(node, left, right, tree, lazy, pending);
    if (right < ql or left > qr) return;
    if (ql <= left and right <= qr) {
        tree[node] = value;
        if (left != right) {
            const child = node * 2;
            lazy[child] = value; lazy[child + 1] = value;
            pending[child] = true; pending[child + 1] = true;
        }
        return;
    }
    const mid = left + (right - left) / 2;
    assignRange(node * 2, left, mid, ql, qr, value, tree, lazy, pending);
    assignRange(node * 2 + 1, mid + 1, right, ql, qr, value, tree, lazy, pending);
    tree[node] = @max(tree[node * 2], tree[node * 2 + 1]);
}

fn rangeMax(node: usize, left: usize, right: usize, ql: usize, qr: usize,
             tree: []i64, lazy: []i64, pending: []bool) i64 {
    push(node, left, right, tree, lazy, pending);
    if (right < ql or left > qr) return std.math.minInt(i64);
    if (ql <= left and right <= qr) return tree[node];
    const mid = left + (right - left) / 2;
    return @max(rangeMax(node * 2, left, mid, ql, qr, tree, lazy, pending),
                rangeMax(node * 2 + 1, mid + 1, right, ql, qr, tree, lazy, pending));
}

export fn lazy_segment_tree_range_set_max(packed: ?[*]const i64, length: usize) i64 {
    if (length < 2 or length > MAX_INPUT) return -1;
    const input = packed orelse return -1;
    const nv = input[0];
    const qv = input[1];
    if (nv < 1 or nv > MAX_N or qv < 0 or qv > MAX_Q) return -1;
    const n: usize = @intCast(nv);
    const q: usize = @intCast(qv);
    if (length < 2 + n) return -1;
    var initial: [MAX_N]i64 = @splat(0);
    for (0..n) |i| {
        initial[i] = input[2 + i];
        if (initial[i] < -1_000_000 or initial[i] > 1_000_000) return -1;
    }
    var offset: usize = 2 + n;
    var opcodes: [MAX_Q]u8 = @splat(0);
    var lefts: [MAX_Q]usize = @splat(0);
    var rights: [MAX_Q]usize = @splat(0);
    var assigned: [MAX_Q]i64 = @splat(0);
    for (0..q) |i| {
        if (offset >= length) return -1;
        const op = input[offset];
        const width: usize = if (op == 0) 3 else if (op == 1) 4 else 0;
        if (width == 0 or offset + width > length) return -1;
        const l = input[offset + 1];
        const r = input[offset + 2];
        if (l < 0 or l >= r or r > nv) return -1;
        opcodes[i] = @intCast(op);
        lefts[i] = @intCast(l);
        rights[i] = @intCast(r);
        if (op == 1) {
            assigned[i] = input[offset + 3];
            if (assigned[i] < -1_000_000 or assigned[i] > 1_000_000) return -1;
        }
        offset += width;
    }
    if (offset != length) return -1;
    var tree: [1024]i64 = @splat(0);
    var lazy: [1024]i64 = @splat(0);
    var pending: [1024]bool = @splat(false);
    build(1, 0, n - 1, initial[0..n], tree[0..]);
    var checksum: i64 = 0;
    var ordinal: i64 = 0;
    for (0..q) |i| {
        if (opcodes[i] == 1) {
            assignRange(1, 0, n - 1, lefts[i], rights[i] - 1, assigned[i], tree[0..], lazy[0..], pending[0..]);
        } else {
            const answer = rangeMax(1, 0, n - 1, lefts[i], rights[i] - 1, tree[0..], lazy[0..], pending[0..]);
            ordinal += 1;
            checksum += ordinal * (answer + CHECKSUM_OFFSET);
        }
    }
    return checksum;
}
