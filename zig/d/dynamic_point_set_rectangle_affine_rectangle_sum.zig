const max_n: usize = 32;
const max_q: usize = 32;
const max_points: usize = max_n + max_q;
const max_tree: usize = 4 * max_points + 8;
const max_input: usize = 2 + 3 * max_n + 7 * max_q + 1;
const modulus: i64 = 998244353;
const max_coord: i64 = 1_000_000_000;

const Op = struct { kind: i64 = 0, a: i64 = 0, b: i64 = 0, c: i64 = 0, d: i64 = 0, e: i64 = 0, f: i64 = 0 };
const Node = struct { min_x: i64 = 0, max_x: i64 = 0, min_y: i64 = 0, max_y: i64 = 0, sum: i64 = 0, lazy_a: i64 = 1, lazy_b: i64 = 0, active: usize = 0 };

fn pointLess(a: usize, b: usize, axis: usize, xs: *const [max_points]i64, ys: *const [max_points]i64) bool {
    const av = if (axis == 0) xs[a] else ys[a];
    const bv = if (axis == 0) xs[b] else ys[b];
    if (av != bv) return av < bv;
    const ao = if (axis == 0) ys[a] else xs[a];
    const bo = if (axis == 0) ys[b] else xs[b];
    if (ao != bo) return ao < bo;
    return a < b;
}
fn sortPoints(order: *[max_points]usize, low: usize, high: usize, axis: usize, xs: *const [max_points]i64, ys: *const [max_points]i64) void {
    var i = low + 1;
    while (i < high) : (i += 1) {
        const point = order[i];
        var j = i;
        while (j > low and pointLess(point, order[j - 1], axis, xs, ys)) : (j -= 1) order[j] = order[j - 1];
        order[j] = point;
    }
}
fn build(tree: *[max_tree]Node, order: *[max_points]usize, rank: *[max_points]usize,
    xs: *const [max_points]i64, ys: *const [max_points]i64, weights: *const [max_points]i64,
    low: usize, high: usize, index: usize, depth: usize, initial_n: usize) void {
    tree[index].lazy_a = 1;
    if (high - low == 1) {
        const p = order[low];
        tree[index].min_x = xs[p]; tree[index].max_x = xs[p];
        tree[index].min_y = ys[p]; tree[index].max_y = ys[p];
        tree[index].active = if (p < initial_n) 1 else 0;
        tree[index].sum = if (p < initial_n) weights[p] else 0;
        rank[p] = low;
        return;
    }
    sortPoints(order, low, high, depth & 1, xs, ys);
    const mid = low + (high - low) / 2;
    build(tree, order, rank, xs, ys, weights, low, mid, index * 2, depth + 1, initial_n);
    build(tree, order, rank, xs, ys, weights, mid, high, index * 2 + 1, depth + 1, initial_n);
    const l = tree[index * 2]; const r = tree[index * 2 + 1];
    tree[index].min_x = @min(l.min_x, r.min_x); tree[index].max_x = @max(l.max_x, r.max_x);
    tree[index].min_y = @min(l.min_y, r.min_y); tree[index].max_y = @max(l.max_y, r.max_y);
    tree[index].active = l.active + r.active;
    tree[index].sum = @mod(l.sum + r.sum, modulus);
}
fn apply(tree: *[max_tree]Node, i: usize, a: i64, b: i64) void {
    if (tree[i].active == 0) return;
    tree[i].sum = @mod(a * tree[i].sum + b * @as(i64, @intCast(tree[i].active)), modulus);
    tree[i].lazy_a = @mod(a * tree[i].lazy_a, modulus);
    tree[i].lazy_b = @mod(a * tree[i].lazy_b + b, modulus);
}
fn push(tree: *[max_tree]Node, i: usize, low: usize, high: usize) void {
    if (high - low == 1 or (tree[i].lazy_a == 1 and tree[i].lazy_b == 0)) return;
    apply(tree, i * 2, tree[i].lazy_a, tree[i].lazy_b);
    apply(tree, i * 2 + 1, tree[i].lazy_a, tree[i].lazy_b);
    tree[i].lazy_a = 1; tree[i].lazy_b = 0;
}
fn disjoint(n: Node, l: i64, d: i64, r: i64, u: i64) bool { return n.max_x < l or n.min_x >= r or n.max_y < d or n.min_y >= u; }
fn covered(n: Node, l: i64, d: i64, r: i64, u: i64) bool { return l <= n.min_x and n.max_x < r and d <= n.min_y and n.max_y < u; }
fn pull(tree: *[max_tree]Node, i: usize) void {
    tree[i].sum = @mod(tree[i * 2].sum + tree[i * 2 + 1].sum, modulus);
    tree[i].active = tree[i * 2].active + tree[i * 2 + 1].active;
}
fn rectSum(tree: *[max_tree]Node, i: usize, low: usize, high: usize, l: i64, d: i64, r: i64, u: i64) i64 {
    const n = tree[i];
    if (n.active == 0 or disjoint(n, l, d, r, u)) return 0;
    if (covered(n, l, d, r, u)) return n.sum;
    push(tree, i, low, high);
    const mid = low + (high - low) / 2;
    return @mod(rectSum(tree, i * 2, low, mid, l, d, r, u) + rectSum(tree, i * 2 + 1, mid, high, l, d, r, u), modulus);
}
fn rectAffine(tree: *[max_tree]Node, i: usize, low: usize, high: usize, l: i64, d: i64, r: i64, u: i64, a: i64, b: i64) void {
    const n = tree[i];
    if (n.active == 0 or disjoint(n, l, d, r, u)) return;
    if (covered(n, l, d, r, u)) { apply(tree, i, a, b); return; }
    push(tree, i, low, high);
    const mid = low + (high - low) / 2;
    rectAffine(tree, i * 2, low, mid, l, d, r, u, a, b);
    rectAffine(tree, i * 2 + 1, mid, high, l, d, r, u, a, b);
    pull(tree, i);
}
fn setPoint(tree: *[max_tree]Node, i: usize, low: usize, high: usize, target: usize, weight: i64) void {
    if (high - low == 1) { tree[i].sum = weight; tree[i].active = 1; tree[i].lazy_a = 1; tree[i].lazy_b = 0; return; }
    push(tree, i, low, high);
    const mid = low + (high - low) / 2;
    if (target < mid) setPoint(tree, i * 2, low, mid, target, weight) else setPoint(tree, i * 2 + 1, mid, high, target, weight);
    pull(tree, i);
}
fn storeLe(out: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[offset + b] = @truncate(bits >> @intCast(b * 8));
}

export fn dynamic_point_set_rectangle_affine_rectangle_sum(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(max_n)) or input[1] < 1 or input[1] > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(input[0]); const q: usize = @intCast(input[1]);
    if (2 + 3 * n > length) return -1;
    var xs = [_]i64{0} ** max_points; var ys = [_]i64{0} ** max_points; var weights = [_]i64{0} ** max_points;
    var ops = [_]Op{.{}} ** max_q;
    var points = n; var active = n; var query_count: usize = 0;
    for (0..n) |i| {
        xs[i] = input[2 + 3 * i]; ys[i] = input[3 + 3 * i]; weights[i] = input[4 + 3 * i];
        if (xs[i] < 0 or xs[i] > max_coord or ys[i] < 0 or ys[i] > max_coord or weights[i] < 0 or weights[i] >= modulus) return -1;
    }
    var cursor: usize = 2 + 3 * n;
    for (0..q) |oi| {
        if (cursor >= length) return -1;
        const kind = input[cursor]; cursor += 1;
        if (kind == 0) {
            if (cursor + 3 > length or points >= max_points) return -1;
            const x = input[cursor]; const y = input[cursor + 1]; const w = input[cursor + 2]; cursor += 3;
            if (x < 0 or x > max_coord or y < 0 or y > max_coord or w < 0 or w >= modulus) return -1;
            xs[points] = x; ys[points] = y; ops[oi] = .{ .kind = kind, .a = @intCast(points), .b = w }; points += 1; active += 1;
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            const id = input[cursor]; const w = input[cursor + 1]; cursor += 2;
            if (id < 0 or id >= @as(i64, @intCast(active)) or w < 0 or w >= modulus) return -1;
            ops[oi] = .{ .kind = kind, .a = id, .b = w };
        } else if (kind == 2 or kind == 3) {
            const fields: usize = if (kind == 2) 4 else 6;
            if (cursor + fields > length) return -1;
            const l = input[cursor]; const d = input[cursor + 1]; const r = input[cursor + 2]; const u = input[cursor + 3];
            if (l < 0 or l >= r or r > max_coord or d < 0 or d >= u or u > max_coord) return -1;
            if (kind == 2) { cursor += 4; ops[oi] = .{ .kind = kind, .a = l, .b = d, .c = r, .d = u }; query_count += 1; }
            else { const a = input[cursor + 4]; const b = input[cursor + 5]; cursor += 6; if (a < 0 or a >= modulus or b < 0 or b >= modulus) return -1; ops[oi] = .{ .kind = kind, .a = l, .b = d, .c = r, .d = u, .e = a, .f = b }; }
        } else return -1;
    }
    if (cursor != length) return -1;
    const output_bytes = 8 * query_count;
    if (output_bytes > 0 and (output_opt == null or capacity < output_bytes)) return -2;
    var tree = [_]Node{.{}} ** max_tree; var order = [_]usize{0} ** max_points; var rank = [_]usize{0} ** max_points;
    for (0..points) |i| order[i] = i;
    build(&tree, &order, &rank, &xs, &ys, &weights, 0, points, 1, 0, n);
    var answers = [_]i64{0} ** max_q; var answer_count: usize = 0;
    for (0..q) |oi| {
        const op = ops[oi];
        if (op.kind == 0 or op.kind == 1) setPoint(&tree, 1, 0, points, rank[@intCast(op.a)], op.b)
        else if (op.kind == 2) { answers[answer_count] = rectSum(&tree, 1, 0, points, op.a, op.b, op.c, op.d); answer_count += 1; }
        else rectAffine(&tree, 1, 0, points, op.a, op.b, op.c, op.d, op.e, op.f);
    }
    if (output_bytes > 0) {
        for (0..answer_count) |i| storeLe(output_opt.?, i * 8, answers[i]);
    }
    return @intCast(output_bytes);
}
