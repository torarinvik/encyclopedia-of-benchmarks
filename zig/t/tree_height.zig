const MAX_NODES: usize = 1023;
const MAX_ARCS: usize = 2 * (MAX_NODES - 1);

fn dfsHeight(node: usize, head: *const [MAX_NODES + 1]i64,
    to: *const [MAX_ARCS]usize, next: *const [MAX_ARCS]i64,
    visited: *[MAX_NODES + 1]bool, dp: *[MAX_NODES + 1]i64, reached: *usize) i64 {
    visited[node] = true;
    reached.* += 1;
    var child_height: i64 = 1;
    var arc = head[node];
    while (arc >= 0) {
        const child = to[@intCast(arc)];
        if (!visited[child]) {
            if (dfsHeight(child, head, to, next, visited, dp, reached) < 0) return -1;
            child_height = @max(child_height, dp[child] + 1);
        }
        arc = next[@intCast(arc)];
    }
    dp[node] = child_height;
    return child_height;
}

export fn tree_height(values: [*]const i64, length: usize) i64 {
    if (length < 1 or values[0] < 1 or values[0] > MAX_NODES) return -1;
    const count: usize = @intCast(values[0]);
    if (length != 1 + 2 * (count - 1)) return -1;
    var head = [_]i64{-1} ** (MAX_NODES + 1);
    var to: [MAX_ARCS]usize = undefined;
    var next: [MAX_ARCS]i64 = undefined;
    var dp = [_]i64{0} ** (MAX_NODES + 1);
    var visited = [_]bool{false} ** (MAX_NODES + 1);
    var arcs: usize = 0;
    for (0..count - 1) |edge| {
        const a_value = values[1 + 2 * edge];
        const b_value = values[2 + 2 * edge];
        if (a_value < 1 or b_value < 1 or a_value > count or b_value > count or a_value == b_value) return -1;
        const a: usize = @intCast(a_value);
        const b: usize = @intCast(b_value);
        to[arcs] = b; next[arcs] = head[a]; head[a] = @intCast(arcs); arcs += 1;
        to[arcs] = a; next[arcs] = head[b]; head[b] = @intCast(arcs); arcs += 1;
    }
    var reached: usize = 0;
    const result = dfsHeight(1, &head, &to, &next, &visited, &dp, &reached);
    if (result < 0 or reached != count) return -1;
    return result;
}
