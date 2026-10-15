const MAX_NODES: usize = 256;
const MAX_QUERIES: usize = 1024;
const MAX_ARCS: usize = 510;
const LOG_LEVELS: usize = 9;

export fn lowest_common_ancestor_binary_lifting(input: [*]const i64, length: usize,
    output: [*]u8, output_capacity: usize) i64 {
    if (length < 4 or input[0] < 1 or input[0] > MAX_NODES) return -1;
    const node_count: usize = @intCast(input[0]);
    if (input[1] < 0 or input[1] >= @as(i64, @intCast(node_count)) or
        input[2] != @as(i64, @intCast(node_count - 1)) or input[3] < 0 or input[3] > MAX_QUERIES) return -1;
    const edge_count: usize = @intCast(input[2]);
    const query_count: usize = @intCast(input[3]);
    const query_offset = 4 + 2 * edge_count;
    if (length != query_offset + 2 * query_count) return -1;
    const root: usize = @intCast(input[1]);

    var head: [MAX_NODES]i32 = @splat(-1);
    var arc_to: [MAX_ARCS]usize = @splat(0);
    var arc_next: [MAX_ARCS]i32 = @splat(-1);
    var parent: [MAX_NODES]i64 = @splat(-2);
    var depth: [MAX_NODES]usize = @splat(0);
    var up: [LOG_LEVELS * MAX_NODES]usize = @splat(0);
    var stack: [MAX_NODES]usize = @splat(0);
    var arcs: usize = 0;
    for (0..edge_count) |edge| {
        const left_value = input[4 + 2 * edge];
        const right_value = input[5 + 2 * edge];
        if (left_value < 0 or left_value >= @as(i64, @intCast(node_count)) or
            right_value < 0 or right_value >= @as(i64, @intCast(node_count)) or left_value == right_value) return -1;
        const left: usize = @intCast(left_value);
        const right: usize = @intCast(right_value);
        arc_to[arcs] = right; arc_next[arcs] = head[left]; head[left] = @intCast(arcs); arcs += 1;
        arc_to[arcs] = left; arc_next[arcs] = head[right]; head[right] = @intCast(arcs); arcs += 1;
    }
    for (0..query_count) |query| {
        for (0..2) |side| {
            const node = input[query_offset + 2 * query + side];
            if (node < 0 or node >= @as(i64, @intCast(node_count))) return -1;
        }
    }
    var top: usize = 0;
    var reached: usize = 0;
    parent[root] = -1;
    up[root] = root;
    stack[top] = root;
    top += 1;
    while (top > 0) {
        top -= 1;
        const node = stack[top];
        reached += 1;
        var arc = head[node];
        while (arc >= 0) {
            const index: usize = @intCast(arc);
            const neighbor = arc_to[index];
            if (@as(i64, @intCast(neighbor)) != parent[node]) {
                if (parent[neighbor] != -2) return -1;
                parent[neighbor] = @intCast(node);
                depth[neighbor] = depth[node] + 1;
                up[neighbor] = node;
                stack[top] = neighbor;
                top += 1;
            }
            arc = arc_next[index];
        }
    }
    if (reached != node_count) return -1;
    if (output_capacity < query_count) return -2;
    for (1..LOG_LEVELS) |level| {
        for (0..node_count) |node| {
            const middle = up[(level - 1) * MAX_NODES + node];
            up[level * MAX_NODES + node] = up[(level - 1) * MAX_NODES + middle];
        }
    }
    for (0..query_count) |query| {
        var u: usize = @intCast(input[query_offset + 2 * query]);
        var v: usize = @intCast(input[query_offset + 2 * query + 1]);
        if (depth[u] < depth[v]) { const temp = u; u = v; v = temp; }
        const difference = depth[u] - depth[v];
        for (0..LOG_LEVELS) |level| {
            if (difference & (@as(usize, 1) << @intCast(level)) != 0) u = up[level * MAX_NODES + u];
        }
        if (u != v) {
            var level = LOG_LEVELS;
            while (level > 0) {
                level -= 1;
                const up_u = up[level * MAX_NODES + u];
                const up_v = up[level * MAX_NODES + v];
                if (up_u != up_v) { u = up_u; v = up_v; }
            }
            u = up[u];
        }
        output[query] = @intCast(u);
    }
    return @intCast(query_count);
}
