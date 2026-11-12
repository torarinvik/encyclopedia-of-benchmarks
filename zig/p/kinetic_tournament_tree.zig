const N: usize = 8;
const M: usize = 32;
const BASE: usize = 8;
const INPUT_MAX: usize = 2 + 2 * N + 4 * M;
const INF: i64 = 1 << 60;

const Node = struct { valid: bool, winner: usize, best: i64, lazy: i64, deadline: i64 };
const Op = struct { kind: i64, left: i64, right: i64, delta: i64 };

fn pull(tree: *[2 * BASE]Node, node: usize, slope: *const [N]i64) void {
    const left = 2 * node;
    const right = left + 1;
    if (!tree[left].valid and !tree[right].valid) {
        tree[node].valid = false;
        tree[node].deadline = INF;
        return;
    }
    if (!tree[left].valid or !tree[right].valid) {
        const child = if (tree[right].valid) right else left;
        tree[node].valid = true;
        tree[node].winner = tree[child].winner;
        tree[node].best = tree[child].best;
        tree[node].deadline = tree[child].deadline;
        return;
    }
    const li = tree[left].winner;
    const ri = tree[right].winner;
    const choose_left = tree[left].best > tree[right].best or (tree[left].best == tree[right].best and slope[li] > slope[ri]);
    const win = if (choose_left) left else right;
    const lose = if (choose_left) right else left;
    const wi = tree[win].winner;
    const lo = tree[lose].winner;
    var crossing: i64 = INF;
    if (slope[wi] < slope[lo]) {
        const gap = tree[win].best - tree[lose].best;
        const slope_gap = slope[lo] - slope[wi];
        crossing = if (gap <= 0) 0 else @divTrunc(gap + slope_gap - 1, slope_gap);
    }
    tree[node].valid = true;
    tree[node].winner = wi;
    tree[node].best = tree[win].best;
    tree[node].deadline = @min(crossing, @min(tree[left].deadline, tree[right].deadline));
}

fn apply(tree: *[2 * BASE]Node, node: usize, slope: *const [N]i64, delta: i64) void {
    if (!tree[node].valid) return;
    tree[node].best += slope[tree[node].winner] * delta;
    tree[node].lazy += delta;
    tree[node].deadline -= delta;
}

fn push(tree: *[2 * BASE]Node, node: usize, slope: *const [N]i64) void {
    const delta = tree[node].lazy;
    if (delta == 0 or node >= BASE) return;
    apply(tree, 2 * node, slope, delta);
    apply(tree, 2 * node + 1, slope, delta);
    tree[node].lazy = 0;
}

fn repair(tree: *[2 * BASE]Node, node: usize, slope: *const [N]i64) void {
    if (node >= BASE or !tree[node].valid) return;
    push(tree, node, slope);
    if (tree[2 * node].valid and tree[2 * node].deadline <= 0) repair(tree, 2 * node, slope);
    if (tree[2 * node + 1].valid and tree[2 * node + 1].deadline <= 0) repair(tree, 2 * node + 1, slope);
    pull(tree, node, slope);
}

fn translate(tree: *[2 * BASE]Node, node: usize, lo: usize, hi: usize,
    ql: usize, qr: usize, delta: i64, slope: *const [N]i64) void {
    if (ql <= lo and hi <= qr) {
        apply(tree, node, slope, delta);
        repair(tree, node, slope);
        return;
    }
    push(tree, node, slope);
    const mid = (lo + hi) / 2;
    if (ql < mid) translate(tree, 2 * node, lo, mid, ql, qr, delta, slope);
    if (mid < qr) translate(tree, 2 * node + 1, mid, hi, ql, qr, delta, slope);
    pull(tree, node, slope);
}

fn query(tree: *[2 * BASE]Node, node: usize, lo: usize, hi: usize,
    ql: usize, qr: usize, slope: *const [N]i64) i64 {
    if (ql <= lo and hi <= qr) return tree[node].best;
    push(tree, node, slope);
    const mid = (lo + hi) / 2;
    var answer: i64 = -9223372036854775807 - 1;
    if (ql < mid) answer = query(tree, 2 * node, lo, mid, ql, qr, slope);
    if (mid < qr) answer = @max(answer, query(tree, 2 * node + 1, mid, hi, ql, qr, slope));
    pull(tree, node, slope);
    return answer;
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn kinetic_tournament_tree(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nr = input[0];
    const mr = input[1];
    if (nr < 1 or nr > @as(i64, @intCast(N)) or mr < 1 or mr > @as(i64, @intCast(M))) return -1;
    const n: usize = @intCast(nr);
    const m: usize = @intCast(mr);
    var cursor: usize = 2;
    var slope: [N]i64 = @splat(0);
    var intercept: [N]i64 = @splat(0);
    for (0..n) |i| {
        if (cursor + 2 > length) return -1;
        slope[i] = input[cursor];
        intercept[i] = input[cursor + 1];
        cursor += 2;
        if (slope[i] < -8 or slope[i] > 8 or intercept[i] < -64 or intercept[i] > 64 or (i > 0 and slope[i] <= slope[i - 1])) return -1;
    }
    var operations: [M]Op = @splat(.{ .kind = 0, .left = 0, .right = 0, .delta = 0 });
    var query_count: usize = 0;
    for (0..m) |i| {
        if (cursor >= length) return -1;
        const kind = input[cursor];
        cursor += 1;
        if (kind == 0) {
            if (cursor + 3 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            const delta = input[cursor + 2];
            cursor += 3;
            if (left < 0 or left > right or right >= nr or delta < 1 or delta > 8) return -1;
            operations[i] = .{ .kind = kind, .left = left, .right = right, .delta = delta };
        } else if (kind == 1) {
            if (cursor + 2 > length) return -1;
            const left = input[cursor];
            const right = input[cursor + 1];
            cursor += 2;
            if (left < 0 or left > right or right >= nr) return -1;
            operations[i] = .{ .kind = kind, .left = left, .right = right, .delta = 0 };
            query_count += 1;
        } else return -1;
    }
    if (cursor != length or query_count == 0) return -1;
    const required = 8 * query_count;
    if (output_opt == null or capacity < required) return -2;

    var tree: [2 * BASE]Node = undefined;
    for (0..2 * BASE) |i| tree[i] = .{ .valid = false, .winner = 0, .best = 0, .lazy = 0, .deadline = INF };
    for (0..n) |i| {
        const node = BASE + i;
        tree[node].valid = true;
        tree[node].winner = i;
        tree[node].best = intercept[i];
    }
    var node = BASE - 1;
    while (node > 0) : (node -= 1) pull(&tree, node, &slope);
    var answers: [M]i64 = @splat(0);
    var answer_count: usize = 0;
    for (0..m) |i| {
        const op = operations[i];
        if (op.kind == 0) {
            translate(&tree, 1, 0, BASE, @intCast(op.left), @intCast(op.right + 1), op.delta, &slope);
        } else {
            answers[answer_count] = query(&tree, 1, 0, BASE, @intCast(op.left), @intCast(op.right + 1), &slope);
            answer_count += 1;
        }
    }
    const output = output_opt.?;
    for (0..answer_count) |i| storeLe(output, 8 * i, answers[i]);
    return @intCast(required);
}
