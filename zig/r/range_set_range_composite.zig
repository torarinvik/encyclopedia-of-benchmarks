const MOD: i64 = 998244353;
const MAX_N: usize = 64;
const MAX_Q: usize = 32;
const MAX_INPUT: usize = 291;
const TREE_N: usize = 4 * MAX_N + 5;

const Affine = struct { a: i64 = 1, b: i64 = 0 };
const Op = struct { kind: i64, left: usize, right: usize, x: i64, y: i64 };
const Node = struct { value: Affine = .{}, lazy_a: i64 = 1, lazy_b: i64 = 0, has_lazy: bool = false };

fn compose(after: Affine, before: Affine) Affine {
    return .{ .a = @mod(after.a * before.a, MOD), .b = @mod(after.a * before.b + after.b, MOD) };
}
fn power_map(a: i64, b: i64, length: usize) Affine {
    var result = Affine{};
    var base = Affine{ .a = a, .b = b };
    var e = length;
    while (e != 0) : (e >>= 1) {
        if ((e & 1) != 0) result = compose(base, result);
        base = compose(base, base);
    }
    return result;
}
fn build(tree: *[TREE_N]Node, node: usize, left: usize, right: usize, a: *const [MAX_N]i64, b: *const [MAX_N]i64) void {
    if (right - left == 1) { tree[node].value = .{ .a = a[left], .b = b[left] }; return; }
    const mid = left + (right - left) / 2;
    build(tree, node * 2, left, mid, a, b); build(tree, node * 2 + 1, mid, right, a, b);
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value);
}
fn apply(tree: *[TREE_N]Node, node: usize, left: usize, right: usize, a: i64, b: i64) void {
    tree[node].value = power_map(a, b, right - left); tree[node].lazy_a = a; tree[node].lazy_b = b; tree[node].has_lazy = true;
}
fn push(tree: *[TREE_N]Node, node: usize, left: usize, right: usize) void {
    if (!tree[node].has_lazy or right - left == 1) return;
    const mid = left + (right - left) / 2; const a = tree[node].lazy_a; const b = tree[node].lazy_b;
    apply(tree, node * 2, left, mid, a, b); apply(tree, node * 2 + 1, mid, right, a, b); tree[node].has_lazy = false;
}
fn update(tree: *[TREE_N]Node, node: usize, left: usize, right: usize, ql: usize, qr: usize, a: i64, b: i64) void {
    if (ql <= left and right <= qr) { apply(tree, node, left, right, a, b); return; }
    push(tree, node, left, right); const mid = left + (right - left) / 2;
    if (ql < mid) update(tree, node * 2, left, mid, ql, qr, a, b);
    if (qr > mid) update(tree, node * 2 + 1, mid, right, ql, qr, a, b);
    tree[node].value = compose(tree[node * 2 + 1].value, tree[node * 2].value);
}
fn query(tree: *[TREE_N]Node, node: usize, left: usize, right: usize, ql: usize, qr: usize) Affine {
    if (ql <= left and right <= qr) return tree[node].value;
    push(tree, node, left, right); const mid = left + (right - left) / 2;
    if (qr <= mid) return query(tree, node * 2, left, mid, ql, qr);
    if (ql >= mid) return query(tree, node * 2 + 1, mid, right, ql, qr);
    return compose(query(tree, node * 2 + 1, mid, right, ql, qr), query(tree, node * 2, left, mid, ql, qr));
}
fn put64(out: [*]u8, offset: usize, value: i64) void { const bits: u64 = @bitCast(value); for (0..8) |j| out[offset + j] = @truncate(bits >> @intCast(8 * j)); }

pub export fn range_set_range_composite(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?; const n64 = input[0]; const q64 = input[1];
    if (n64 < 1 or n64 > MAX_N or q64 < 1 or q64 > MAX_Q) return -1;
    const n: usize = @intCast(n64); const q: usize = @intCast(q64);
    var initial_a = [_]i64{0} ** MAX_N; var initial_b = [_]i64{0} ** MAX_N;
    var offset: usize = 2;
    if (length < offset + 2 * n) return -1;
    for (0..n) |i| { initial_a[i] = input[offset]; initial_b[i] = input[offset + 1]; offset += 2; if (initial_a[i] < 1 or initial_a[i] >= MOD or initial_b[i] < 0 or initial_b[i] >= MOD) return -1; }
    var ops = [_]Op{.{ .kind = 0, .left = 0, .right = 0, .x = 0, .y = 0 }} ** MAX_Q; var answer_count: usize = 0;
    for (0..q) |k| {
        if (offset >= length) return -1; const kind = input[offset]; offset += 1;
        if (kind == 0) {
            if (offset + 4 > length) return -1; const l = input[offset]; const r = input[offset + 1]; const a = input[offset + 2]; const b = input[offset + 3]; offset += 4;
            if (l < 0 or l >= r or r > n64 or a < 1 or a >= MOD or b < 0 or b >= MOD) return -1;
            ops[k] = .{ .kind = 0, .left = @intCast(l), .right = @intCast(r), .x = a, .y = b };
        } else if (kind == 1) {
            if (offset + 3 > length) return -1; const l = input[offset]; const r = input[offset + 1]; const x = input[offset + 2]; offset += 3;
            if (l < 0 or l >= r or r > n64 or x < 0 or x >= MOD) return -1;
            ops[k] = .{ .kind = 1, .left = @intCast(l), .right = @intCast(r), .x = x, .y = 0 }; answer_count += 1;
        } else return -1;
    }
    if (offset != length) return -1;
    var tree = [_]Node{.{}} ** TREE_N; build(&tree, 1, 0, n, &initial_a, &initial_b);
    var answers = [_]i64{0} ** MAX_Q; var ai: usize = 0;
    for (0..q) |k| { const op = ops[k]; if (op.kind == 0) update(&tree, 1, 0, n, op.left, op.right, op.x, op.y) else { const v = query(&tree, 1, 0, n, op.left, op.right); answers[ai] = @mod(v.a * op.x + v.b, MOD); ai += 1; } }
    const bytes = 8 * answer_count; if (output_opt == null or capacity < bytes) return -2; const output = output_opt.?;
    for (0..answer_count) |i| put64(output, 8 * i, answers[i]); return @intCast(bytes);
}
