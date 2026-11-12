const MAX_N: usize = 32;
const MAX_Q: usize = 64;
const MAX_INPUT: usize = 3 * MAX_N + 5 * MAX_Q + 1;
const MAX_VALUE: i64 = 1000;

const Node = struct {
    child: [2]i32 = .{ -1, -1 },
    parent: i32 = -1,
    reversed: bool = false,
    value: i64 = 0,
    virtual_sum: i64 = 0,
    sum: i64 = 0,
};

fn isAuxRoot(nodes: *const [MAX_N]Node, x: usize) bool {
    const parent = nodes[x].parent;
    return parent < 0 or (nodes[@intCast(parent)].child[0] != @as(i32, @intCast(x)) and
        nodes[@intCast(parent)].child[1] != @as(i32, @intCast(x)));
}
fn nodeSum(nodes: *const [MAX_N]Node, x: i32) i64 {
    if (x < 0) return 0;
    return nodes[@intCast(x)].sum;
}
fn pull(nodes: *[MAX_N]Node, x: usize) void {
    const left = nodes[x].child[0];
    const right = nodes[x].child[1];
    nodes[x].sum = nodes[x].value + nodes[x].virtual_sum + nodeSum(nodes, left) + nodeSum(nodes, right);
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
        const gp: usize = @intCast(g);
        const side: usize = if (nodes[gp].child[1] == @as(i32, @intCast(p))) 1 else 0;
        nodes[gp].child[side] = @intCast(x);
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
        const old_right = nodes[index].child[1];
        nodes[index].virtual_sum += nodeSum(nodes, old_right) - nodeSum(nodes, last);
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
fn linkNodes(nodes: *[MAX_N]Node, u: usize, v: usize) bool {
    if (u == v) return false;
    makeRoot(nodes, u);
    if (findRoot(nodes, v) == u) return false;
    access(nodes, v);
    nodes[u].parent = @intCast(v);
    nodes[v].virtual_sum += nodes[u].sum;
    pull(nodes, v);
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
fn subtreeSideSum(nodes: *[MAX_N]Node, vertex: usize, parent: usize) ?i64 {
    makeRoot(nodes, parent);
    access(nodes, vertex);
    if (nodes[vertex].child[0] != @as(i32, @intCast(parent)) or nodes[parent].child[1] >= 0) return null;
    return nodes[vertex].value + nodes[vertex].virtual_sum;
}
fn putI64(output: [*c]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn dynamic_tree_vertex_add_subtree_sum(input: [*c]const i64, input_length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or input_length < 3 or input_length > MAX_INPUT) return -1;
    const n_value = input[0];
    const q_value = input[1];
    if (n_value < 1 or n_value > 32 or q_value < 0 or q_value > 64) return -1;
    const n: usize = @intCast(n_value);
    const q: usize = @intCast(q_value);
    if (input_length != 3 * n + 5 * q) return -1;
    for (0..n) |i| if (input[2 + i] < 0 or input[2 + i] > MAX_VALUE) return -1;
    const edge_start = 2 + n;
    const operation_start = edge_start + 2 * (n - 1);
    for (0..(n - 1)) |i| {
        const u = input[edge_start + 2 * i];
        const v = input[edge_start + 2 * i + 1];
        if (u < 0 or u >= n_value or v < 0 or v >= n_value or u == v) return -1;
    }
    for (0..q) |i| {
        const at = operation_start + 5 * i;
        const kind = input[at];
        const a = input[at + 1];
        const b = input[at + 2];
        const c = input[at + 3];
        const d = input[at + 4];
        if (kind == 0) {
            if (a < 0 or a >= n_value or b < 0 or b >= n_value or c < 0 or c >= n_value or d < 0 or d >= n_value or a == b or c == d) return -1;
        } else if (kind == 1) {
            if (a < 0 or a >= n_value or b < 0 or b > MAX_VALUE or c != 0 or d != 0) return -1;
        } else if (kind == 2) {
            if (a < 0 or a >= n_value or b < 0 or b >= n_value or c != 0 or d != 0) return -1;
        } else return -1;
    }
    var nodes: [MAX_N]Node = undefined;
    for (0..n) |i| {
        nodes[i] = .{
            .child = .{ -1, -1 },
            .parent = -1,
            .reversed = false,
            .value = input[2 + i],
            .virtual_sum = 0,
            .sum = input[2 + i],
        };
    }
    for (0..(n - 1)) |i| {
        if (!linkNodes(&nodes, @intCast(input[edge_start + 2 * i]), @intCast(input[edge_start + 2 * i + 1]))) return -1;
    }
    var answers: [MAX_Q]i64 = [_]i64{0} ** MAX_Q;
    var answer_count: usize = 0;
    for (0..q) |i| {
        const at = operation_start + 5 * i;
        const kind: usize = @intCast(input[at]);
        const a: usize = @intCast(input[at + 1]);
        const b: usize = @intCast(input[at + 2]);
        if (kind == 0) {
            const c: usize = @intCast(input[at + 3]);
            const d: usize = @intCast(input[at + 4]);
            if (!cutNodes(&nodes, a, b) or !linkNodes(&nodes, c, d)) return -1;
        } else if (kind == 1) {
            access(&nodes, a);
            nodes[a].value += @intCast(b);
            pull(&nodes, a);
        } else {
            const answer = subtreeSideSum(&nodes, a, b) orelse return -1;
            answers[answer_count] = answer;
            answer_count += 1;
        }
    }
    const output_bytes = 8 * answer_count;
    if (output_bytes > 0 and (output == null or output_capacity < output_bytes)) return -2;
    for (0..answer_count) |i| putI64(output, 8 * i, answers[i]);
    return @intCast(output_bytes);
}
