const MAX_N: usize = 8;
const MAX_Q: usize = 12;
const MAX_INPUT: usize = 93;
const MODULUS: i64 = 998244353;

const Affine = struct { multiplier: i64 = 1, addend: i64 = 0 };
const Node = struct {
    child: [2]i32 = .{ -1, -1 },
    parent: i32 = -1,
    reversed: bool = false,
    value: Affine = .{},
    forward: Affine = .{},
    backward: Affine = .{},
};
const Query = struct { kind: i64 = 0, a: i64 = 0, b: i64 = 0, c: i64 = 0, d: i64 = 0 };

fn compose(after: Affine, before: Affine) Affine {
    return .{
        .multiplier = @rem(after.multiplier * before.multiplier, MODULUS),
        .addend = @rem(after.multiplier * before.addend + after.addend, MODULUS),
    };
}
fn isAuxRoot(nodes: *const [MAX_N]Node, x: usize) bool {
    const p = nodes[x].parent;
    return p < 0 or (nodes[@intCast(p)].child[0] != @as(i32, @intCast(x)) and
        nodes[@intCast(p)].child[1] != @as(i32, @intCast(x)));
}
fn pull(nodes: *[MAX_N]Node, x: usize) void {
    const left = nodes[x].child[0];
    const right = nodes[x].child[1];
    const lf = if (left < 0) Affine{} else nodes[@intCast(left)].forward;
    const rf = if (right < 0) Affine{} else nodes[@intCast(right)].forward;
    const lb = if (left < 0) Affine{} else nodes[@intCast(left)].backward;
    const rb = if (right < 0) Affine{} else nodes[@intCast(right)].backward;
    nodes[x].forward = compose(rf, compose(nodes[x].value, lf));
    nodes[x].backward = compose(lb, compose(nodes[x].value, rb));
}
fn reversePath(nodes: *[MAX_N]Node, x_value: i32) void {
    if (x_value < 0) return;
    const x: usize = @intCast(x_value);
    const temporary = nodes[x].child[0];
    nodes[x].child[0] = nodes[x].child[1];
    nodes[x].child[1] = temporary;
    const aggregate = nodes[x].forward;
    nodes[x].forward = nodes[x].backward;
    nodes[x].backward = aggregate;
    nodes[x].reversed = !nodes[x].reversed;
}
fn push(nodes: *[MAX_N]Node, x: usize) void {
    if (!nodes[x].reversed) return;
    reversePath(nodes, nodes[x].child[0]);
    reversePath(nodes, nodes[x].child[1]);
    nodes[x].reversed = false;
}
fn rotate(nodes: *[MAX_N]Node, x: usize) void {
    const p: usize = @intCast(nodes[x].parent);
    const g = nodes[p].parent;
    const direction: usize = if (nodes[p].child[1] == @as(i32, @intCast(x))) 1 else 0;
    const middle = nodes[x].child[direction ^ 1];
    if (!isAuxRoot(nodes, p)) {
        const gi: usize = @intCast(g);
        const side: usize = if (nodes[gi].child[1] == @as(i32, @intCast(p))) 1 else 0;
        nodes[gi].child[side] = @intCast(x);
    }
    nodes[x].parent = g;
    nodes[x].child[direction ^ 1] = @intCast(p);
    nodes[p].parent = @intCast(x);
    nodes[p].child[direction] = middle;
    if (middle >= 0) nodes[@intCast(middle)].parent = @intCast(p);
    pull(nodes, p);
    pull(nodes, x);
}
fn splay(nodes: *[MAX_N]Node, x: usize) void {
    var stack: [MAX_N]usize = undefined;
    var count: usize = 1;
    var y = x;
    stack[0] = y;
    while (!isAuxRoot(nodes, y)) {
        y = @intCast(nodes[y].parent);
        stack[count] = y;
        count += 1;
    }
    while (count > 0) {
        count -= 1;
        push(nodes, stack[count]);
    }
    while (!isAuxRoot(nodes, x)) {
        const p: usize = @intCast(nodes[x].parent);
        if (!isAuxRoot(nodes, p)) {
            const g: usize = @intCast(nodes[p].parent);
            const zig_zig = (nodes[p].child[0] == @as(i32, @intCast(x))) ==
                (nodes[g].child[0] == @as(i32, @intCast(p)));
            rotate(nodes, if (zig_zig) p else x);
        }
        rotate(nodes, x);
    }
}
fn access(nodes: *[MAX_N]Node, x: usize) void {
    var last: i32 = -1;
    var y: i32 = @intCast(x);
    while (y >= 0) {
        const index: usize = @intCast(y);
        splay(nodes, index);
        nodes[index].child[1] = last;
        if (last >= 0) nodes[@intCast(last)].parent = y;
        pull(nodes, index);
        last = y;
        y = nodes[index].parent;
    }
    splay(nodes, x);
}
fn makeRoot(nodes: *[MAX_N]Node, x: usize) void {
    access(nodes, x);
    reversePath(nodes, @intCast(x));
}
fn findRoot(nodes: *[MAX_N]Node, x: usize) usize {
    access(nodes, x);
    push(nodes, x);
    var root = x;
    while (nodes[root].child[0] >= 0) {
        root = @intCast(nodes[root].child[0]);
        push(nodes, root);
    }
    splay(nodes, root);
    return root;
}
fn linkNodes(nodes: *[MAX_N]Node, u: usize, v: usize) bool {
    if (u == v) return false;
    makeRoot(nodes, u);
    if (findRoot(nodes, v) == u) return false;
    nodes[u].parent = @intCast(v);
    return true;
}
fn cutNodes(nodes: *[MAX_N]Node, u: usize, v: usize) bool {
    if (u == v) return false;
    makeRoot(nodes, u);
    access(nodes, v);
    if (nodes[v].child[0] != @as(i32, @intCast(u)) or nodes[u].child[1] >= 0) return false;
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    return true;
}
fn setValue(nodes: *[MAX_N]Node, vertex: usize, value: Affine) void {
    access(nodes, vertex);
    nodes[vertex].value = value;
    pull(nodes, vertex);
}
fn pathComposition(nodes: *[MAX_N]Node, u: usize, v: usize) ?Affine {
    makeRoot(nodes, u);
    if (findRoot(nodes, v) != u) return null;
    makeRoot(nodes, u);
    access(nodes, v);
    return nodes[v].forward;
}
fn findDsu(parent: *[MAX_N]usize, item: usize) usize {
    var node = item;
    while (parent[node] != node) {
        parent[node] = parent[parent[node]];
        node = parent[node];
    }
    return node;
}
fn connected(adjacency: *const [MAX_N][MAX_N]bool, n: usize, start: usize, target: usize) bool {
    var seen: [MAX_N]bool = @splat(false);
    var stack: [MAX_N]usize = undefined;
    var top: usize = 1;
    seen[start] = true;
    stack[0] = start;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        if (u == target) return true;
        for (0..n) |v| {
            if (adjacency[u][v] and !seen[v]) {
                seen[v] = true;
                stack[top] = v;
                top += 1;
            }
        }
    }
    return false;
}
fn storeI64Le(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn dynamic_tree_vertex_set_path_composite(input: [*c]const i64, length: usize,
    output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > MAX_INPUT) return -1;
    const packed = input[0..length];
    const n_value = packed[0];
    const q_value = packed[1];
    if (n_value < 1 or n_value > MAX_N or q_value < 1 or q_value > MAX_Q) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (length < 2 + 2 * n + 2 * (n - 1) + 4 * q) return -1;

    var values: [MAX_N]Affine = @splat(.{});
    for (0..n) |i| {
        const multiplier = packed[2 + 2 * i];
        const addend = packed[3 + 2 * i];
        if (multiplier < 1 or multiplier >= MODULUS or addend < 0 or addend >= MODULUS) return -1;
        values[i] = .{ .multiplier = multiplier, .addend = addend };
    }

    var adjacency: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var dsu: [MAX_N]usize = @splat(0);
    var edge_u: [MAX_N]usize = @splat(0);
    var edge_v: [MAX_N]usize = @splat(0);
    for (0..n) |i| dsu[i] = i;
    var cursor: usize = 2 + 2 * n;
    for (0..(n - 1)) |edge| {
        const u_value = packed[cursor];
        const v_value = packed[cursor + 1];
        cursor += 2;
        if (u_value < 0 or u_value >= n_value or v_value < 0 or v_value >= n_value or u_value == v_value) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        const root_u = findDsu(&dsu, u);
        const root_v = findDsu(&dsu, v);
        if (root_u == root_v) return -1;
        dsu[root_v] = root_u;
        adjacency[u][v] = true;
        adjacency[v][u] = true;
        edge_u[edge] = u;
        edge_v[edge] = v;
    }

    var queries: [MAX_Q]Query = @splat(.{});
    var answer_count: usize = 0;
    for (0..q) |i| {
        if (cursor >= length) return -1;
        var current = Query{ .kind = packed[cursor] };
        cursor += 1;
        if (current.kind == 0) {
            if (length - cursor < 4) return -1;
            current.a = packed[cursor]; current.b = packed[cursor + 1];
            current.c = packed[cursor + 2]; current.d = packed[cursor + 3];
            cursor += 4;
            if (current.a < 0 or current.a >= n_value or current.b < 0 or current.b >= n_value or
                current.c < 0 or current.c >= n_value or current.d < 0 or current.d >= n_value or
                current.a == current.b or current.c == current.d) return -1;
            const u: usize = @intCast(current.a); const v: usize = @intCast(current.b);
            const w: usize = @intCast(current.c); const x: usize = @intCast(current.d);
            if (!adjacency[u][v]) return -1;
            adjacency[u][v] = false; adjacency[v][u] = false;
            if (connected(&adjacency, n, w, x)) return -1;
            adjacency[w][x] = true; adjacency[x][w] = true;
        } else if (current.kind == 1) {
            if (length - cursor < 3) return -1;
            current.a = packed[cursor]; current.b = packed[cursor + 1]; current.c = packed[cursor + 2]; cursor += 3;
            if (current.a < 0 or current.a >= n_value or current.b < 1 or current.b >= MODULUS or
                current.c < 0 or current.c >= MODULUS) return -1;
        } else if (current.kind == 2) {
            if (length - cursor < 3) return -1;
            current.a = packed[cursor]; current.b = packed[cursor + 1]; current.c = packed[cursor + 2]; cursor += 3;
            if (current.a < 0 or current.a >= n_value or current.b < 0 or current.b >= n_value or
                current.c < 0 or current.c >= MODULUS) return -1;
            answer_count += 1;
        } else return -1;
        queries[i] = current;
    }
    if (cursor != length) return -1;
    const required = 8 * answer_count;
    if (output == null or capacity < required) return -2;

    var nodes: [MAX_N]Node = @splat(.{});
    for (0..MAX_N) |i| {
        nodes[i].child = .{ -1, -1 };
        nodes[i].parent = -1;
    }
    for (0..n) |i| {
        nodes[i].value = values[i];
        nodes[i].forward = values[i];
        nodes[i].backward = values[i];
    }
    for (0..(n - 1)) |edge| {
        if (!linkNodes(&nodes, edge_u[edge], edge_v[edge])) return -1;
    }

    var answers: [MAX_Q]i64 = @splat(0);
    var written: usize = 0;
    for (queries[0..q]) |query| {
        if (query.kind == 0) {
            if (!cutNodes(&nodes, @intCast(query.a), @intCast(query.b)) or
                !linkNodes(&nodes, @intCast(query.c), @intCast(query.d))) return -1;
        } else if (query.kind == 1) {
            setValue(&nodes, @intCast(query.a), .{ .multiplier = query.b, .addend = query.c });
        } else {
            const combined = pathComposition(&nodes, @intCast(query.a), @intCast(query.b)) orelse return -1;
            answers[written] = @rem(combined.multiplier * query.c + combined.addend, MODULUS);
            written += 1;
        }
    }
    for (0..written) |i| storeI64Le(output, 8 * i, answers[i]);
    return @intCast(required);
}
