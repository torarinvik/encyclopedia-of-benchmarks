const N: usize = 10;
const M: usize = 45;
const MAX_INPUT: usize = 92;
const DN: usize = 20;

fn pairVertexFlow(adjacency: [N]u64, n: usize, source_vertex: usize,
    target_vertex: usize, limit: i64) i64 {
    var residual: [DN*DN]i64 = @splat(0);
    const nodes = 2*n;
    for (0..n) |v| {
        residual[(2*v)*DN+2*v+1] = if (v==source_vertex or v==target_vertex) @intCast(n) else 1;
    }
    for (0..n) |u| {
        for (u+1..n) |v| {
            if ((adjacency[u] & (@as(u64,1) << @intCast(v))) != 0) {
                residual[(2*u+1)*DN+2*v] = 1;
                residual[(2*v+1)*DN+2*u] = 1;
            }
        }
    }
    const source = 2*source_vertex+1;
    const sink = 2*target_vertex;
    var flow: i64 = 0;
    while (flow < limit) {
        var parent: [DN]i32 = @splat(-1);
        var queue: [DN]usize = @splat(0);
        parent[source] = @intCast(source);
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail and parent[sink] < 0) {
            const u = queue[head];
            head += 1;
            for (0..nodes) |v| {
                if (parent[v] < 0 and residual[u*DN+v] > 0) {
                    parent[v] = @intCast(u);
                    queue[tail] = v;
                    tail += 1;
                    if (v == sink) break;
                }
            }
        }
        if (parent[sink] < 0) break;
        var amount = limit-flow;
        var v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            amount = @min(amount, residual[u*DN+v]);
            v = u;
        }
        v = sink;
        while (v != source) {
            const u: usize = @intCast(parent[v]);
            residual[u*DN+v] -= amount;
            residual[v*DN+u] += amount;
            v = u;
        }
        flow += amount;
    }
    return flow;
}

export fn vertex_connectivity(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 0 or input[0] > @as(i64,@intCast(N)) or
        input[1] < 0 or input[1] > @as(i64,@intCast(M))) return -1;
    const n: usize = @intCast(input[0]);
    const m: usize = @intCast(input[1]);
    if (length != 2+2*m) return -1;
    var adjacency: [N]u64 = @splat(0);
    for (0..m) |e| {
        const left = input[2+2*e];
        const right = input[3+2*e];
        if (left < 0 or right < 0 or left >= @as(i64,@intCast(n)) or right >= @as(i64,@intCast(n))) return -1;
        if (left != right) {
            const u: usize = @intCast(left);
            const v: usize = @intCast(right);
            adjacency[u] |= @as(u64,1) << @intCast(v);
            adjacency[v] |= @as(u64,1) << @intCast(u);
        }
    }
    if (n <= 1) return 0;
    var reached: u64 = 1;
    var graph_queue: [N]usize = @splat(0);
    var graph_head: usize = 0;
    var graph_tail: usize = 1;
    graph_queue[0] = 0;
    while (graph_head < graph_tail) {
        const u = graph_queue[graph_head];
        graph_head += 1;
        for (0..n) |v| {
            const bit = @as(u64,1) << @intCast(v);
            if ((adjacency[u] & bit) != 0 and (reached & bit) == 0) {
                reached |= bit;
                graph_queue[graph_tail] = v;
                graph_tail += 1;
            }
        }
    }
    if (reached != ((@as(u64,1) << @intCast(n))-1)) return 0;
    var best: i64 = @as(i64,@intCast(n))-1;
    for (0..n) |source| {
        for (source+1..n) |target| {
            if ((adjacency[source] & (@as(u64,1) << @intCast(target))) != 0) continue;
            const flow = pairVertexFlow(adjacency,n,source,target,best);
            if (flow < best) best = flow;
            if (best == 0) return 0;
        }
    }
    return best;
}
