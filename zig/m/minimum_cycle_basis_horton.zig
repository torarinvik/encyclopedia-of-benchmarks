const MIN_N: usize = 3;
const MAX_N: usize = 8;
const MAX_M: usize = 12;
const MAX_LENGTH: usize = 39;
const MAX_CANDIDATES: usize = 96;
const INF: i64 = 0x3fffffffffffffff;

const Edge = struct { u: usize, v: usize, weight: i64 };

fn cycleWeight(mask: u64, edges: [MAX_M]Edge, m: usize) i64 {
    var total: i64 = 0;
    for (0..m) |e| if ((mask >> @as(u6, @intCast(e))) & 1 != 0) { total += edges[e].weight; };
    return total;
}

fn hortonWeight(n: usize, m: usize, edges: [MAX_M]Edge) i64 {
    var candidates: [MAX_CANDIDATES]u64 = @splat(0);
    var costs: [MAX_CANDIDATES]i64 = @splat(0);
    var candidate_count: usize = 0;
    for (0..n) |root| {
        var distance: [MAX_N]i64 = @splat(INF);
        var parent: [MAX_N]usize = @splat(MAX_N);
        var parent_edge: [MAX_N]usize = @splat(MAX_M);
        var settled: [MAX_N]bool = @splat(false);
        var tree_edge: [MAX_M]bool = @splat(false);
        var path_mask: [MAX_N]u64 = @splat(0);
        distance[root] = 0;
        const tie_scale: i64 = @as(i64, @intCast(m + 1)) * (@as(i64, 1) << @as(u6, @intCast(m)));
        for (0..n) |_| {
            var vertex: ?usize = null;
            for (0..n) |v| {
                if (!settled[v] and distance[v] != INF) {
                    if (vertex == null or distance[v] < distance[vertex.?] or
                        (distance[v] == distance[vertex.?] and v < vertex.?)) vertex = v;
                }
            }
            if (vertex == null) break;
            const u = vertex.?;
            settled[u] = true;
            for (0..m) |e| {
                const edge = edges[e];
                const v = if (edge.u == u) edge.v else if (edge.v == u) edge.u else continue;
                if (settled[v]) continue;
                const next_distance = distance[u] + edge.weight * tie_scale + (@as(i64, 1) << @as(u6, @intCast(e)));
                if (next_distance < distance[v]) {
                    distance[v] = next_distance;
                    parent[v] = u;
                    parent_edge[v] = e;
                }
            }
        }
        for (0..n) |v| {
            if (v == root) continue;
            var cursor = v;
            var steps: usize = 0;
            while (cursor != root and steps < n) : (steps += 1) {
                const pe = parent_edge[cursor];
                if (pe == MAX_M) return -1;
                tree_edge[pe] = true;
                path_mask[v] |= @as(u64, 1) << @as(u6, @intCast(pe));
                cursor = parent[cursor];
            }
            if (cursor != root) return -1;
        }
        for (0..m) |e| {
            if (tree_edge[e]) continue;
            const edge = edges[e];
            const cycle = path_mask[edge.u] ^ path_mask[edge.v] ^ (@as(u64, 1) << @as(u6, @intCast(e)));
            if (cycle == 0) continue;
            var duplicate = false;
            for (0..candidate_count) |i| if (candidates[i] == cycle) { duplicate = true; break; };
            if (!duplicate and candidate_count < MAX_CANDIDATES) {
                candidates[candidate_count] = cycle;
                costs[candidate_count] = cycleWeight(cycle, edges, m);
                candidate_count += 1;
            }
        }
    }
    for (0..candidate_count) |i| for (i + 1..candidate_count) |j| {
        if (costs[j] < costs[i] or (costs[j] == costs[i] and candidates[j] < candidates[i])) {
            const old_cost = costs[i]; costs[i] = costs[j]; costs[j] = old_cost;
            const old_mask = candidates[i]; candidates[i] = candidates[j]; candidates[j] = old_mask;
        }
    };
    const dimension = m - n + 1;
    var basis: [MAX_M]u64 = @splat(0);
    var rank: usize = 0;
    var total: i64 = 0;
    for (0..candidate_count) |i| {
        if (rank == dimension) break;
        var residual = candidates[i];
        var bit = m;
        while (bit > 0) {
            bit -= 1;
            const flag = @as(u64, 1) << @as(u6, @intCast(bit));
            if ((residual & flag) == 0) continue;
            if (basis[bit] != 0) {
                residual ^= basis[bit];
            } else {
                basis[bit] = residual;
                rank += 1;
                total += costs[i];
                break;
            }
        }
    }
    return if (rank == dimension) total else -1;
}

export fn minimum_cycle_basis_horton(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < @as(i64, @intCast(MIN_N)) or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    if (input[1] < @as(i64, @intCast(n - 1)) or input[1] > @as(i64, @intCast(MAX_M)) or
        input[1] > @as(i64, @intCast(n * (n - 1) / 2))) return -1;
    const m: usize = @intCast(input[1]);
    if (length != 2 + 3 * m) return -1;
    var edges: [MAX_M]Edge = undefined;
    var adjacent: [MAX_N][MAX_N]bool = @splat(@splat(false));
    var previous_u: ?usize = null;
    var previous_v: usize = 0;
    for (0..m) |e| {
        const u_value = input[2 + 3 * e];
        const v_value = input[3 + 3 * e];
        const weight = input[4 + 3 * e];
        if (u_value < 0 or v_value < 0 or u_value >= @as(i64, @intCast(n)) or
            v_value >= @as(i64, @intCast(n)) or u_value >= v_value or weight < 1 or weight > 9) return -1;
        const u: usize = @intCast(u_value);
        const v: usize = @intCast(v_value);
        if (previous_u) |pu| {
            if (u < pu or (u == pu and v <= previous_v)) return -1;
        }
        previous_u = u; previous_v = v;
        edges[e] = .{ .u = u, .v = v, .weight = weight };
        adjacent[u][v] = true; adjacent[v][u] = true;
    }
    var seen: [MAX_N]bool = @splat(false);
    var queue: [MAX_N]usize = @splat(0);
    var head: usize = 0; var tail: usize = 1;
    seen[0] = true; queue[0] = 0;
    while (head < tail) : (head += 1) {
        const u = queue[head];
        for (0..n) |v| if (adjacent[u][v] and !seen[v]) { seen[v] = true; queue[tail] = v; tail += 1; };
    }
    for (0..n) |v| if (!seen[v]) return -1;
    return hortonWeight(n, m, edges);
}
