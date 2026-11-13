const N_MAX: usize = 8;
const M_MAX: usize = 24;
const INPUT_MAX: usize = 77;

fn dfs(u: usize, sink: usize, amount: i64, n: usize, residual: *[64]i64,
    distance: *[8]i64, gap: *[9]i64, current: *[8]usize, stopped: *bool) i64 {
    if (u == sink) return amount;
    while (current[u] < n) {
        const v = current[u];
        const edge = u * N_MAX + v;
        if (residual[edge] > 0 and distance[u] == distance[v] + 1) {
            const limit = if (amount < residual[edge]) amount else residual[edge];
            const sent = dfs(v, sink, limit, n, residual, distance, gap, current, stopped);
            if (sent > 0) {
                residual[edge] -= sent;
                residual[v * N_MAX + u] += sent;
                return sent;
            }
            if (stopped.*) return 0;
        }
        current[u] += 1;
    }
    const old = distance[u];
    var best: i64 = @intCast(n);
    for (0..n) |v| {
        if (residual[u * N_MAX + v] > 0 and distance[v] < best) best = distance[v];
    }
    var replacement = best + 1;
    if (replacement > @as(i64, @intCast(n))) replacement = @intCast(n);
    gap[@intCast(old)] -= 1;
    distance[u] = replacement;
    gap[@intCast(replacement)] += 1;
    current[u] = 0;
    if (old < @as(i64, @intCast(n)) and gap[@intCast(old)] == 0) stopped.* = true;
    return 0;
}

export fn isap_maxflow(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 4 or length > INPUT_MAX) return -1;
    const input = input_opt.?;
    const nv = input[0];
    const mv = input[1];
    const sv = input[2];
    const tv = input[3];
    if (nv < 2 or nv > @as(i64, @intCast(N_MAX)) or mv < 0 or mv > @as(i64, @intCast(M_MAX)) or
        sv < 0 or sv >= nv or tv < 0 or tv >= nv or sv == tv) return -1;
    const n: usize = @intCast(nv);
    const m: usize = @intCast(mv);
    const source: usize = @intCast(sv);
    const sink: usize = @intCast(tv);
    if (length != 4 + 3 * m) return -1;
    var residual: [64]i64 = @splat(0);
    for (0..m) |e| {
        const u = input[4 + 3 * e];
        const v = input[5 + 3 * e];
        const capacity = input[6 + 3 * e];
        if (u < 0 or u >= nv or v < 0 or v >= nv or u == v or capacity < 0 or capacity > 100) return -1;
        residual[@as(usize, @intCast(u)) * N_MAX + @as(usize, @intCast(v))] += capacity;
    }
    var distance: [8]i64 = @splat(@intCast(n));
    var gap: [9]i64 = @splat(0);
    var current: [8]usize = @splat(0);
    var queue: [8]usize = undefined;
    distance[sink] = 0;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = sink;
    while (head < tail) {
        const v = queue[head];
        head += 1;
        for (0..n) |p| {
            if (distance[p] == @as(i64, @intCast(n)) and residual[p * N_MAX + v] > 0) {
                distance[p] = distance[v] + 1;
                queue[tail] = p;
                tail += 1;
            }
        }
    }
    if (distance[source] >= @as(i64, @intCast(n))) return 0;
    for (0..n) |v| gap[@intCast(distance[v])] += 1;
    var stopped = false;
    var flow: i64 = 0;
    while (distance[source] < @as(i64, @intCast(n)) and !stopped) {
        flow += dfs(source, sink, 2400, n, &residual, &distance, &gap, &current, &stopped);
    }
    return flow;
}
