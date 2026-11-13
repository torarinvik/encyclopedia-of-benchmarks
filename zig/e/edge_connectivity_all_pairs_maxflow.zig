const MAX_VERTICES: usize = 10;
const MAX_EDGES: usize = 45;
const MAX_PARSEABLE: usize = 93;

fn pairFlow(adjacency: [MAX_VERTICES][MAX_VERTICES]i64, n: usize,
    source: usize, sink: usize, limit: i64) i64 {
    var residual = adjacency;
    var flow: i64 = 0;
    while (flow < limit) {
        var parent: [MAX_VERTICES]i32 = @splat(-1);
        var queue: [MAX_VERTICES]usize = @splat(0);
        parent[source] = @intCast(source);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..n) |v| {
                if (parent[v] < 0 and residual[u][v] > 0) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        var amount = limit - flow;
        var v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            amount = @min(amount, residual[u][v]);
            v = u;
        }
        v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            residual[u][v] -= amount;
            residual[v][u] += amount;
            v = u;
        }
        flow += amount;
    }
    return flow;
}

export fn edge_connectivity_all_pairs_maxflow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_PARSEABLE) return -1;
    const input = input_opt.?[0..length];
    if (input[0] < 2 or input[0] > @as(i64, @intCast(MAX_VERTICES)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_EDGES))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2 + 2 * m) return -1;

    var adjacency: [MAX_VERTICES][MAX_VERTICES]i64 = @splat(@splat(0));
    for (0..m) |e| {
        const left = input[2 + 2 * e];
        const right = input[3 + 2 * e];
        if (left < 0 or right < 0 or left >= @as(i64, @intCast(n)) or
            right >= @as(i64, @intCast(n)) or left == right) return -1;
        const u: usize = @intCast(left);
        const v: usize = @intCast(right);
        if (adjacency[u][v] != 0) return -1;
        adjacency[u][v] = 1;
        adjacency[v][u] = 1;
    }

    var best: i64 = @as(i64, @intCast(n)) - 1;
    for (0..n) |source| {
        for (source + 1..n) |sink| {
            const flow = pairFlow(adjacency, n, source, sink, best);
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
