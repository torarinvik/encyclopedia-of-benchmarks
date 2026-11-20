const std = @import("std");

const max_n: usize = 64;
const max_q: usize = 64;
const max_input: usize = 320;
const max_weight: i64 = 1_000_000;
const neg: i64 = -1152921504606846976;
const Matrix = [2][2]i64;

fn identity() Matrix { return .{ .{ 0, neg }, .{ neg, 0 } }; }

fn maximum(a: i64, b: i64) i64 { return if (a > b) a else b; }

fn multiply(a: Matrix, b: Matrix) Matrix {
    var result: Matrix = undefined;
    for (0..2) |row| for (0..2) |col| {
        result[row][col] = maximum(a[row][0] + b[0][col], a[row][1] + b[1][col]);
    };
    return result;
}

fn findRoot(parent: *[max_n]usize, start: usize) usize {
    var v = start;
    while (parent[v] != v) { parent[v] = parent[parent[v]]; v = parent[v]; }
    return v;
}

fn setMatrix(tree: *[2 * max_n]Matrix, position: usize, value: Matrix) void {
    var node = max_n + position;
    tree[node] = value;
    node /= 2;
    while (node > 0) { tree[node] = multiply(tree[2 * node], tree[2 * node + 1]); node /= 2; }
}

fn query(tree: *const [2 * max_n]Matrix, left: usize, right: usize) Matrix {
    var l = max_n + left;
    var r = max_n + right;
    var before = identity();
    var after = identity();
    while (l < r) {
        if (l % 2 == 1) { before = multiply(before, tree[l]); l += 1; }
        if (r % 2 == 1) { r -= 1; after = multiply(tree[r], after); }
        l /= 2; r /= 2;
    }
    return multiply(before, after);
}

fn summary(tree: *const [2 * max_n]Matrix, position: *const [max_n]usize,
    tail: *const [max_n]usize, head: usize) [2]i64 {
    const p = query(tree, position[head], position[tail[head]] + 1);
    return .{ maximum(p[0][0], p[0][1]), maximum(p[1][0], p[1][1]) };
}

fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dynamic_tree_maximum_weight_independent_set(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > max_input) return -1;
    const input = input_opt.?;
    const nn = input[0]; const qq = input[1];
    if (nn < 1 or nn > @as(i64, @intCast(max_n)) or qq < 0 or qq > @as(i64, @intCast(max_q))) return -1;
    const n: usize = @intCast(nn); const q: usize = @intCast(qq);
    const edge_end = 2 + n + 2 * (n - 1);
    if (length != edge_end + 2 * q) return -1;

    var dsu = [_]usize{0} ** max_n;
    var weights = [_]i64{0} ** max_n;
    var adjacency = [_]bool{false} ** (max_n * max_n);
    for (0..n) |u| {
        dsu[u] = u; weights[u] = input[2 + u];
        if (weights[u] < 0 or weights[u] > max_weight) return -1;
    }
    for (0..n - 1) |edge| {
        const offset = 2 + n + 2 * edge;
        const uu = input[offset]; const vv = input[offset + 1];
        if (uu < 0 or uu >= nn or vv < 0 or vv >= nn or uu == vv) return -1;
        const u: usize = @intCast(uu); const v: usize = @intCast(vv);
        const ru = findRoot(&dsu, u); const rv = findRoot(&dsu, v);
        if (ru == rv) return -1;
        dsu[ru] = rv; adjacency[u * max_n + v] = true; adjacency[v * max_n + u] = true;
    }
    const root_set = findRoot(&dsu, 0);
    for (1..n) |v| {
        if (findRoot(&dsu, v) != root_set) return -1;
    }

    var update_vertex = [_]usize{0} ** max_q;
    var update_weight = [_]i64{0} ** max_q;
    for (0..q) |i| {
        const offset = edge_end + 2 * i;
        const vertex = input[offset]; const weight = input[offset + 1];
        if (vertex < 0 or vertex >= nn or weight < 0 or weight > max_weight) return -1;
        update_vertex[i] = @intCast(vertex); update_weight[i] = weight;
    }
    const output_bytes = 8 * q;
    const output = output_opt orelse { if (output_bytes > 0) return -2; return 0; };
    if (output_bytes > 0 and capacity < output_bytes) return -2;

    var parent = [_]i32{-2} ** max_n;
    var order = [_]usize{0} ** max_n;
    parent[0] = -1; order[0] = 0;
    var order_count: usize = 1; var cursor: usize = 0;
    while (cursor < order_count) : (cursor += 1) {
        const u = order[cursor];
        for (0..n) |v| {
            if (adjacency[u * max_n + v] and parent[v] == -2) {
                parent[v] = @intCast(u); order[order_count] = v; order_count += 1;
            }
        }
    }

    var subtree = [_]usize{1} ** max_n;
    var heavy = [_]i32{-1} ** max_n;
    var skip = [_]i64{0} ** max_n;
    var take = [_]i64{0} ** max_n;
    for (0..n) |u| take[u] = weights[u];
    var index = n;
    while (index > 1) {
        index -= 1;
        const u = order[index]; const p: usize = @intCast(parent[u]);
        subtree[p] += subtree[u];
        if (heavy[p] < 0 or subtree[u] > subtree[@intCast(heavy[p])]) heavy[p] = @intCast(u);
        skip[p] += maximum(skip[u], take[u]); take[p] += skip[u];
    }

    var head = [_]usize{0} ** max_n;
    var position = [_]usize{0} ** max_n;
    var tail = [_]usize{0} ** max_n;
    var stack = [_]usize{0} ** max_n;
    var stack_len: usize = 1; var clock: usize = 0; stack[0] = 0;
    while (stack_len > 0) {
        stack_len -= 1; const h = stack[stack_len]; var u: i32 = @intCast(h);
        while (u >= 0) {
            const vertex: usize = @intCast(u);
            head[vertex] = h; position[vertex] = clock; clock += 1; tail[h] = vertex;
            for (1..n) |v| {
                if (parent[v] == u and heavy[vertex] != @as(i32, @intCast(v))) {
                    stack[stack_len] = v; stack_len += 1;
                }
            }
            u = heavy[vertex];
        }
    }

    var matrices = [_]Matrix{identity()} ** max_n;
    var segment = [_]Matrix{identity()} ** (2 * max_n);
    for (0..n) |u| {
        var light0: i64 = 0; var light1 = weights[u];
        for (1..n) |v| {
            if (parent[v] == @as(i32, @intCast(u)) and heavy[u] != @as(i32, @intCast(v))) {
                light0 += maximum(skip[v], take[v]); light1 += skip[v];
            }
        }
        matrices[u] = .{ .{ light0, light0 }, .{ light1, neg } };
        segment[max_n + position[u]] = matrices[u];
    }
    var build = max_n;
    while (build > 1) { build -= 1; segment[build] = multiply(segment[2 * build], segment[2 * build + 1]); }

    var staged = [_]i64{0} ** max_q;
    for (0..q) |i| {
        const vertex = update_vertex[i]; var h = head[vertex];
        var old_state = summary(&segment, &position, &tail, h);
        const delta = update_weight[i] - weights[vertex]; weights[vertex] = update_weight[i];
        matrices[vertex][1][0] += delta; setMatrix(&segment, position[vertex], matrices[vertex]);
        var new_state = summary(&segment, &position, &tail, h);
        while (parent[h] != -1) {
            const p: usize = @intCast(parent[h]); const ph = head[p];
            const before = summary(&segment, &position, &tail, ph);
            const d0 = maximum(new_state[0], new_state[1]) - maximum(old_state[0], old_state[1]);
            const d1 = new_state[0] - old_state[0];
            matrices[p][0][0] += d0; matrices[p][0][1] += d0; matrices[p][1][0] += d1;
            setMatrix(&segment, position[p], matrices[p]); old_state = before;
            new_state = summary(&segment, &position, &tail, ph); h = ph;
        }
        const answer = summary(&segment, &position, &tail, 0);
        staged[i] = maximum(answer[0], answer[1]);
    }
    for (0..q) |i| storeLe(output, 8 * i, staged[i]);
    return @intCast(output_bytes);
}
