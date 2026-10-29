const MAX_N: usize = 16;
const MAX_INPUT: usize = 210;

const Node = struct {
    child: [2]i32,
    parent: i32,
    reversed: bool,
    value: i64,
    sum: i64,
};

fn isAuxRoot(nodes: *const [MAX_N]Node, x: usize) bool {
    const parent = nodes[x].parent;
    return parent < 0 or (nodes[@intCast(parent)].child[0] != @as(i32, @intCast(x)) and
        nodes[@intCast(parent)].child[1] != @as(i32, @intCast(x)));
}
fn pull(nodes: *[MAX_N]Node, x: usize) void {
    const left = nodes[x].child[0];
    const right = nodes[x].child[1];
    const left_sum: i64 = if (left < 0) 0 else nodes[@intCast(left)].sum;
    const right_sum: i64 = if (right < 0) 0 else nodes[@intCast(right)].sum;
    nodes[x].sum = nodes[x].value + left_sum + right_sum;
}
fn toggleReverse(nodes: *[MAX_N]Node, x: i32) void {
    if (x < 0) return;
    const index: usize = @intCast(x);
    const temp = nodes[index].child[0];
    nodes[index].child[0] = nodes[index].child[1];
    nodes[index].child[1] = temp;
    nodes[index].reversed = !nodes[index].reversed;
}
fn push(nodes: *[MAX_N]Node, x: usize) void {
    if (!nodes[x].reversed) return;
    toggleReverse(nodes, nodes[x].child[0]);
    toggleReverse(nodes, nodes[x].child[1]);
    nodes[x].reversed = false;
}
fn rotate(nodes: *[MAX_N]Node, x: usize) void {
    const p: usize = @intCast(nodes[x].parent);
    const g = nodes[p].parent;
    const direction: usize = if (nodes[p].child[1] == @as(i32, @intCast(x))) 1 else 0;
    const middle = nodes[x].child[direction ^ 1];
    if (!isAuxRoot(nodes, p)) {
        const g_index: usize = @intCast(g);
        const side: usize = if (nodes[g_index].child[1] == @as(i32, @intCast(p))) 1 else 0;
        nodes[g_index].child[side] = @intCast(x);
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
    toggleReverse(nodes, @intCast(x));
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
fn linkNodes(nodes: *[MAX_N]Node, u: usize, v: usize) i64 {
    if (u == v) return 0;
    makeRoot(nodes, u);
    if (findRoot(nodes, v) == u) return 0;
    nodes[u].parent = @intCast(v);
    return 1;
}
fn cutNodes(nodes: *[MAX_N]Node, u: usize, v: usize) i64 {
    if (u == v) return 0;
    makeRoot(nodes, u);
    access(nodes, v);
    if (nodes[v].child[0] != @as(i32, @intCast(u)) or nodes[u].child[1] >= 0) return 0;
    nodes[v].child[0] = -1;
    nodes[u].parent = -1;
    pull(nodes, v);
    return 1;
}
fn pathSum(nodes: *[MAX_N]Node, u: usize, v: usize) i64 {
    makeRoot(nodes, u);
    if (findRoot(nodes, v) != u) return -1;
    makeRoot(nodes, u);
    access(nodes, v);
    return nodes[v].sum;
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn link_cut_tree(input: [*c]const i64, input_length: usize,
                        output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 2 or input_length > MAX_INPUT) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > 16 or q_value < 1 or q_value > 64) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (input_length != 2 + n + 3 * q) return -1;
    for (0..n) |i| if (input[2 + i] < 0 or input[2 + i] > 1_000_000) return -1;
    const operations_at = 2 + n;
    for (0..q) |i| {
        const at = operations_at + 3 * i;
        const op = input[at];
        const u = input[at + 1];
        const v = input[at + 2];
        if (op < 0 or op > 2 or u < 0 or u >= n_value or v < 0 or v >= n_value) return -1;
    }
    const bytes = 8 * q;
    if (output == null or output_capacity < bytes) return -2;
    var nodes: [MAX_N]Node = undefined;
    for (0..n) |i| {
        nodes[i] = .{ .child = .{ -1, -1 }, .parent = -1, .reversed = false,
            .value = input[2 + i], .sum = input[2 + i] };
    }
    for (0..q) |i| {
        const at = operations_at + 3 * i;
        const op: usize = @intCast(input[at]);
        const u: usize = @intCast(input[at + 1]);
        const v: usize = @intCast(input[at + 2]);
        const result = switch (op) {
            0 => linkNodes(&nodes, u, v),
            1 => cutNodes(&nodes, u, v),
            else => pathSum(&nodes, u, v),
        };
        putI64(output, 8 * i, result);
    }
    return @intCast(bytes);
}
