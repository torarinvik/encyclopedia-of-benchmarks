const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 2 * (MAX_NODES - 1);
const MAX_INPUT: usize = 4 + 2 * (MAX_NODES - 1) + 2 * MAX_QUERIES;

fn lowbit(value: u32) u32 { return value & (0 -% value); }

fn highbit(value: u32) u32 {
    var rest = value;
    var result: u32 = 0;
    while (rest != 0) : (rest >>= 1) result = rest;
    return result;
}

export fn schieber_vishkin_lca(input: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (input == null or length < 4 or length > MAX_INPUT + 1) return -1;
    if (input[0] < 1 or input[0] > MAX_NODES) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= @as(i64, @intCast(n)) or
        input[2] != @as(i64, @intCast(n - 1)) or input[3] < 0 or input[3] > MAX_QUERIES) return -1;
    const m: usize = @intCast(input[2]);
    const q: usize = @intCast(input[3]);
    const query_offset = 4 + 2 * m;
    if (length != query_offset + 2 * q) return -1;
    const root: usize = @intCast(input[1]);

    var head: [MAX_NODES]i32 = @splat(-1);
    var arc_to: [MAX_ARCS]usize = @splat(0);
    var arc_next: [MAX_ARCS]i32 = @splat(-1);
    var parent: [MAX_NODES]i32 = @splat(-2);
    var order: [MAX_NODES]usize = @splat(0);
    var stack_node: [MAX_NODES]usize = @splat(0);
    var stack_arc: [MAX_NODES]i32 = @splat(-1);
    var preorder: [MAX_NODES]usize = @splat(0);
    var inlabel: [MAX_NODES]u32 = @splat(0);
    var ascendant: [MAX_NODES]u32 = @splat(0);
    var path_head: [MAX_NODES]usize = @splat(0);
    var answers: [MAX_QUERIES]u8 = @splat(0);

    var arcs: usize = 0;
    for (0..m) |edge| {
        const a = input[4 + 2 * edge];
        const b = input[5 + 2 * edge];
        if (a < 0 or a >= @as(i64, @intCast(n)) or b < 0 or b >= @as(i64, @intCast(n)) or a == b) return -1;
        const u: usize = @intCast(a);
        const v: usize = @intCast(b);
        arc_to[arcs] = v; arc_next[arcs] = head[u]; head[u] = @intCast(arcs); arcs += 1;
        arc_to[arcs] = u; arc_next[arcs] = head[v]; head[v] = @intCast(arcs); arcs += 1;
    }
    for (0..q) |query| {
        for (0..2) |side| {
            const node = input[query_offset + 2 * query + side];
            if (node < 0 or node >= @as(i64, @intCast(n))) return -1;
        }
    }

    var reached: usize = 1;
    var top: usize = 1;
    parent[root] = -1;
    preorder[root] = 1;
    order[0] = root;
    stack_node[0] = root;
    stack_arc[0] = head[root];
    while (top > 0) {
        const slot = top - 1;
        const node = stack_node[slot];
        const arc = stack_arc[slot];
        if (arc < 0) { top -= 1; continue; }
        const arc_index: usize = @intCast(arc);
        stack_arc[slot] = arc_next[arc_index];
        const neighbor = arc_to[arc_index];
        if (@as(i32, @intCast(neighbor)) == parent[node]) continue;
        if (parent[neighbor] != -2) return -1;
        parent[neighbor] = @intCast(node);
        preorder[neighbor] = reached + 1;
        order[reached] = neighbor;
        reached += 1;
        stack_node[top] = neighbor;
        stack_arc[top] = head[neighbor];
        top += 1;
    }
    if (reached != n) return -1;
    if (output_capacity < q or (q != 0 and output == null)) return -2;

    for (0..n) |node| inlabel[node] = @intCast(preorder[node]);
    var i = n;
    while (i > 1) {
        i -= 1;
        const node = order[i];
        const p: usize = @intCast(parent[node]);
        if (lowbit(inlabel[p]) < lowbit(inlabel[node])) inlabel[p] = inlabel[node];
    }
    for (0..n) |position| {
        const node = order[position];
        if (parent[node] < 0) {
            ascendant[node] = lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = node;
        } else {
            const p: usize = @intCast(parent[node]);
            ascendant[node] = ascendant[p] | lowbit(inlabel[node]);
            path_head[preorder[node] - 1] = if (inlabel[node] != inlabel[p]) p else path_head[preorder[p] - 1];
        }
    }

    for (0..q) |query| {
        const u: usize = @intCast(input[query_offset + 2 * query]);
        const v: usize = @intCast(input[query_offset + 2 * query + 1]);
        const lu = lowbit(inlabel[u]);
        const lv = lowbit(inlabel[v]);
        var mask = highbit((inlabel[u] ^ inlabel[v]) | lu | lv) - 1;
        const j = lowbit(ascendant[u] & ascendant[v] & ~mask);
        if (j == 0) return -1;
        var x = u;
        var y = v;
        if (j != lu) {
            mask = highbit(ascendant[u] & (j - 1)) - 1;
            const index = ((preorder[u] & ~@as(usize, @intCast(mask))) | (@as(usize, @intCast(mask)) + 1)) - 1;
            x = path_head[index];
        }
        if (j != lv) {
            mask = highbit(ascendant[v] & (j - 1)) - 1;
            const index = ((preorder[v] & ~@as(usize, @intCast(mask))) | (@as(usize, @intCast(mask)) + 1)) - 1;
            y = path_head[index];
        }
        answers[query] = @intCast(if (preorder[x] < preorder[y]) x else y);
    }
    for (0..q) |query| output[query] = answers[query];
    return @intCast(q);
}
