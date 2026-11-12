const N: usize = 8;
const M: usize = 32;
const NODES: usize = N + 2 * M;
const INPUT_MAX: usize = 2 + N + 3 * M;

const Op = struct { kind: i64, a: i64, b: i64 };
const SplitResult = struct { first: i32, rest: i32 };
const Tree = struct {
    left: [NODES]i32,
    right: [NODES]i32,
    parent: [NODES]i32,
    vertex: [NODES]i32,
    size: [NODES]i32,
    count: [NODES]i32,
    value: [NODES]i64,
    total: [NODES]i64,
    priority: [NODES]u64,
    edge_u: [M]i32,
    edge_v: [M]i32,
    arc_uv: [M]i32,
    arc_vu: [M]i32,
    active: [M]bool,
    next_node: usize,
    edge_count: usize,
};

fn mix(input: u64) u64 {
    var x = input +% 0x9e3779b97f4a7c15;
    x = (x ^ (x >> 30)) *% 0xbf58476d1ce4e5b9;
    x = (x ^ (x >> 27)) *% 0x94d049bb133111eb;
    return x ^ (x >> 31);
}
fn sizeOf(tree: *const Tree, node: i32) i32 { return if (node < 0) 0 else tree.size[@intCast(node)]; }
fn countOf(tree: *const Tree, node: i32) i32 { return if (node < 0) 0 else tree.count[@intCast(node)]; }
fn totalOf(tree: *const Tree, node: i32) i64 { return if (node < 0) 0 else tree.total[@intCast(node)]; }
fn pull(tree: *Tree, node: i32) void {
    if (node < 0) return;
    const i: usize = @intCast(node);
    tree.size[i] = 1 + sizeOf(tree, tree.left[i]) + sizeOf(tree, tree.right[i]);
    tree.count[i] = (if (tree.vertex[i] >= 0) @as(i32, 1) else 0) + countOf(tree, tree.left[i]) + countOf(tree, tree.right[i]);
    tree.total[i] = tree.value[i] + totalOf(tree, tree.left[i]) + totalOf(tree, tree.right[i]);
}
fn merge(tree: *Tree, a: i32, b: i32) i32 {
    if (a < 0) { if (b >= 0) tree.parent[@intCast(b)] = -1; return b; }
    if (b < 0) { tree.parent[@intCast(a)] = -1; return a; }
    const ai: usize = @intCast(a);
    const bi: usize = @intCast(b);
    if (tree.priority[ai] > tree.priority[bi]) {
        const child = merge(tree, tree.right[ai], b);
        tree.right[ai] = child;
        if (child >= 0) tree.parent[@intCast(child)] = a;
        pull(tree, a);
        tree.parent[ai] = -1;
        return a;
    }
    const child = merge(tree, a, tree.left[bi]);
    tree.left[bi] = child;
    if (child >= 0) tree.parent[@intCast(child)] = b;
    pull(tree, b);
    tree.parent[bi] = -1;
    return b;
}
fn split(tree: *Tree, root: i32, prefix: i32) SplitResult {
    if (root < 0) return .{ .first = -1, .rest = -1 };
    const i: usize = @intCast(root);
    if (prefix <= sizeOf(tree, tree.left[i])) {
        const pair = split(tree, tree.left[i], prefix);
        tree.left[i] = pair.rest;
        if (pair.rest >= 0) tree.parent[@intCast(pair.rest)] = root;
        pull(tree, root);
        tree.parent[i] = -1;
        if (pair.first >= 0) tree.parent[@intCast(pair.first)] = -1;
        return .{ .first = pair.first, .rest = root };
    }
    const left_size = sizeOf(tree, tree.left[i]);
    const pair = split(tree, tree.right[i], prefix - left_size - 1);
    tree.right[i] = pair.first;
    if (pair.first >= 0) tree.parent[@intCast(pair.first)] = root;
    pull(tree, root);
    tree.parent[i] = -1;
    if (pair.rest >= 0) tree.parent[@intCast(pair.rest)] = -1;
    return .{ .first = root, .rest = pair.rest };
}
fn rootOf(tree: *const Tree, node0: i32) i32 {
    var node = node0;
    while (tree.parent[@intCast(node)] >= 0) node = tree.parent[@intCast(node)];
    return node;
}
fn position(tree: *const Tree, node0: i32) i32 {
    var node = node0;
    var result = sizeOf(tree, tree.left[@intCast(node)]);
    while (tree.parent[@intCast(node)] >= 0) {
        const p = tree.parent[@intCast(node)];
        if (tree.right[@intCast(p)] == node) result += 1 + sizeOf(tree, tree.left[@intCast(p)]);
        node = p;
    }
    return result;
}
fn rotate(tree: *Tree, root: i32, node: i32) i32 {
    const pair = split(tree, root, position(tree, node));
    return merge(tree, pair.rest, pair.first);
}
fn reachable(adjacency: *const [N * N]bool, start: usize, target: usize, n: usize) bool {
    var seen = [_]bool{false} ** N;
    var stack = [_]usize{0} ** N;
    var top: usize = 1;
    stack[0] = start;
    seen[start] = true;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        if (u == target) return true;
        for (0..n) |v| {
            if (adjacency[u * N + v] and !seen[v]) { seen[v] = true; stack[top] = v; top += 1; }
        }
    }
    return false;
}
fn initialize(tree: *Tree, weights: *const [N]i64, n: usize) void {
    tree.* = .{
        .left = @splat(-1), .right = @splat(-1), .parent = @splat(-1), .vertex = @splat(-1),
        .size = @splat(0), .count = @splat(0), .value = @splat(0), .total = @splat(0),
        .priority = undefined, .edge_u = @splat(0), .edge_v = @splat(0), .arc_uv = @splat(0), .arc_vu = @splat(0),
        .active = @splat(false), .next_node = n, .edge_count = 0,
    };
    for (0..NODES) |i| tree.priority[i] = mix(i);
    for (0..n) |i| { tree.vertex[i] = @intCast(i); tree.value[i] = weights[i]; tree.total[i] = weights[i]; tree.size[i] = 1; tree.count[i] = 1; }
}
fn link(tree: *Tree, u: usize, v: usize) void {
    const ui: i32 = @intCast(u); const vi: i32 = @intCast(v);
    const a = rotate(tree, rootOf(tree, ui), ui);
    const b = rotate(tree, rootOf(tree, vi), vi);
    const uv: i32 = @intCast(tree.next_node); const vu = uv + 1; tree.next_node += 2;
    for ([2]i32{ uv, vu }) |arc| {
        const i: usize = @intCast(arc);
        tree.left[i] = -1; tree.right[i] = -1; tree.parent[i] = -1; tree.vertex[i] = -1;
        tree.value[i] = 0; tree.total[i] = 0; tree.size[i] = 1; tree.count[i] = 0;
    }
    const root = merge(tree, merge(tree, merge(tree, a, uv), b), vu);
    tree.parent[@intCast(root)] = -1;
    const e = tree.edge_count; tree.edge_count += 1;
    tree.edge_u[e] = @intCast(u); tree.edge_v[e] = @intCast(v); tree.arc_uv[e] = uv; tree.arc_vu[e] = vu; tree.active[e] = true;
}
fn cut(tree: *Tree, u: usize, v: usize) void {
    var edge: ?usize = null;
    var offset = tree.edge_count;
    while (offset > 0) {
        offset -= 1;
        if (tree.active[offset] and ((tree.edge_u[offset] == u and tree.edge_v[offset] == v) or (tree.edge_u[offset] == v and tree.edge_v[offset] == u))) { edge = offset; break; }
    }
    const e = edge.?;
    const first_arc = if (tree.edge_u[e] == u and tree.edge_v[e] == v) tree.arc_uv[e] else tree.arc_vu[e];
    const second_arc = if (first_arc == tree.arc_uv[e]) tree.arc_vu[e] else tree.arc_uv[e];
    const root = rotate(tree, rootOf(tree, first_arc), first_arc);
    const removed = split(tree, root, 1);
    const pair = split(tree, removed.rest, position(tree, second_arc));
    const other = split(tree, pair.rest, 1);
    if (pair.first >= 0) tree.parent[@intCast(pair.first)] = -1;
    if (other.rest >= 0) tree.parent[@intCast(other.rest)] = -1;
    tree.active[e] = false;
}
fn setWeight(tree: *Tree, vertex: usize, value: i64) void {
    tree.value[vertex] = value;
    var path: [NODES]i32 = undefined;
    var count: usize = 0;
    var node: i32 = @intCast(vertex);
    while (node >= 0) { path[count] = node; count += 1; node = tree.parent[@intCast(node)]; }
    for (0..count) |i| pull(tree, path[i]);
}
fn storeLe(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn euler_tour_tree(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nr = input[0]; const mr = input[1];
    if (nr < 1 or nr > N or mr < 1 or mr > M) return -1;
    const n: usize = @intCast(nr); const m: usize = @intCast(mr); var cursor: usize = 2;
    var weights: [N]i64 = @splat(0);
    for (0..n) |i| { if (cursor >= length) return -1; weights[i] = input[cursor]; cursor += 1; if (weights[i] < -100 or weights[i] > 100) return -1; }
    var operations: [M]Op = @splat(.{ .kind = 0, .a = 0, .b = 0 });
    var query_count: usize = 0;
    for (0..m) |i| {
        if (cursor >= length) return -1;
        const kind = input[cursor]; cursor += 1;
        if (kind == 0 or kind == 1) {
            if (cursor + 2 > length) return -1;
            const u = input[cursor]; const v = input[cursor + 1]; cursor += 2;
            if (u < 0 or u >= nr or v < 0 or v >= nr or u == v) return -1;
            operations[i] = .{ .kind = kind, .a = u, .b = v };
        } else if (kind == 2) {
            if (cursor + 2 > length) return -1;
            const vertex = input[cursor]; const value = input[cursor + 1]; cursor += 2;
            if (vertex < 0 or vertex >= nr or value < -100 or value > 100) return -1;
            operations[i] = .{ .kind = kind, .a = vertex, .b = value };
        } else if (kind == 3) {
            if (cursor >= length) return -1;
            const vertex = input[cursor]; cursor += 1;
            if (vertex < 0 or vertex >= nr) return -1;
            operations[i] = .{ .kind = kind, .a = vertex, .b = 0 }; query_count += 1;
        } else return -1;
    }
    if (cursor != length or query_count == 0) return -1;
    var adjacency: [N * N]bool = @splat(false);
    for (0..m) |i| {
        const op = operations[i]; const u: usize = @intCast(op.a); const v: usize = @intCast(op.b);
        if (op.kind == 0) { if (reachable(&adjacency, u, v, n)) return -1; adjacency[u * N + v] = true; adjacency[v * N + u] = true; }
        else if (op.kind == 1) { if (!adjacency[u * N + v]) return -1; adjacency[u * N + v] = false; adjacency[v * N + u] = false; }
    }
    const required = 16 * query_count;
    if (output_opt == null or capacity < required) return -2;
    var tree: Tree = undefined; initialize(&tree, &weights, n);
    var answers: [2 * M]i64 = @splat(0); var answer_count: usize = 0;
    for (0..m) |i| {
        const op = operations[i]; const a: usize = @intCast(op.a); const b: usize = @intCast(op.b);
        if (op.kind == 0) link(&tree, a, b)
        else if (op.kind == 1) cut(&tree, a, b)
        else if (op.kind == 2) setWeight(&tree, a, op.b)
        else { const root: usize = @intCast(rootOf(&tree, @intCast(a))); answers[answer_count] = @as(i64, tree.count[root]); answers[answer_count + 1] = tree.total[root]; answer_count += 2; }
    }
    const output = output_opt.?;
    for (0..answer_count) |i| storeLe(output, 8 * i, answers[i]);
    return @intCast(required);
}
