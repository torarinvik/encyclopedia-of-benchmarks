const N: usize = 8;
const M: usize = 16;
const F: usize = 10;
const MAX_INPUT: usize = 79;
const MAX_NODES: usize = 20;
const MAX_EDGES: usize = 200;
const INF: i64 = 1 << 60;
const Edge = struct { from: usize, to: usize, rev: usize, cap: i64, cost: i64 };

fn connected(adj: *const [N][N]bool, n: usize, removed: isize) bool {
    const start: usize = if (removed == 0) 1 else 0;
    var seen = [_]bool{false} ** N;
    var stack = [_]usize{0} ** N;
    var top: usize = 1; var count: usize = 0;
    stack[0] = start; seen[start] = true;
    while (top > 0) {
        top -= 1; const u = stack[top]; count += 1;
        for (0..n) |v| if (@as(isize, @intCast(v)) != removed and adj[u][v] and !seen[v]) {
            seen[v] = true; stack[top] = v; top += 1;
        };
    }
    return count == n - @as(usize, @intCast(if (removed >= 0) 1 else 0));
}

fn addArc(edges: *[MAX_EDGES]Edge, count: *usize, u: usize, v: usize, cap: i64, cost: i64) bool {
    if (count.* + 2 > MAX_EDGES) return false;
    const e = count.*;
    edges[e] = .{ .from = u, .to = v, .rev = e + 1, .cap = cap, .cost = cost };
    edges[e + 1] = .{ .from = v, .to = u, .rev = e, .cap = 0, .cost = -cost };
    count.* += 2;
    return true;
}

pub export fn orthogonal_drawing_minimum_bends(
    input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize,
) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > MAX_INPUT) return -1;
    const n0 = input[0]; const m0 = input[1]; const f0 = input[2]; const outer0 = input[3];
    if (n0 < 3 or n0 > 8 or m0 < n0 or m0 > 16 or f0 < 2 or f0 > 10 or
        f0 != m0 - n0 + 2 or outer0 < 0 or outer0 >= f0) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    const f: usize = @intCast(f0); const outer: usize = @intCast(outer0);
    var adj = [_][N]bool{[_]bool{false} ** N} ** N;
    var degree = [_]usize{0} ** N;
    var eu = [_]usize{0} ** M; var ev = [_]usize{0} ** M;
    var uses = [_][N]usize{[_]usize{0} ** N} ** N;
    var p: usize = 4;
    for (0..m) |e| {
        if (p + 2 > length) return -1;
        const u0 = input[p]; const v0 = input[p + 1]; p += 2;
        if (u0 < 0 or u0 >= v0 or v0 >= n0) return -1;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        if (adj[u][v] or (e > 0 and (u < eu[e - 1] or (u == eu[e - 1] and v <= ev[e - 1])))) return -1;
        adj[u][v] = true; adj[v][u] = true; degree[u] += 1; degree[v] += 1; eu[e] = u; ev[e] = v;
    }
    for (0..n) |v| if (degree[v] < 2 or degree[v] > 4) return -1;
    var face = [_][N]usize{[_]usize{0} ** N} ** F;
    var width = [_]usize{0} ** F;
    var link_adj = [_][N][N]bool{[_][N]bool{[_]bool{false} ** N} ** N} ** N;
    var link_degree = [_][N]usize{[_]usize{0} ** N} ** N;
    for (0..f) |g| {
        if (p >= length) return -1;
        const w0 = input[p]; p += 1;
        if (w0 < 3 or w0 > n0 or p + @as(usize, @intCast(w0)) > length) return -1;
        width[g] = @intCast(w0);
        var row = [_]bool{false} ** N;
        for (0..width[g]) |i| {
            const x0 = input[p]; p += 1;
            if (x0 < 0 or x0 >= n0 or row[@as(usize, @intCast(x0))]) return -1;
            const x: usize = @intCast(x0); row[x] = true; face[g][i] = x;
        }
        for (0..width[g]) |i| {
            const u = face[g][i]; const v = face[g][(i + 1) % width[g]];
            if (!adj[u][v]) return -1;
            uses[u][v] += 1;
        }
        for (0..width[g]) |i| {
            const center = face[g][i];
            const before = face[g][(i + width[g] - 1) % width[g]];
            const after = face[g][(i + 1) % width[g]];
            if (before == after) return -1;
            link_adj[center][before][after] = true;
            link_adj[center][after][before] = true;
            link_degree[center][before] += 1;
            link_degree[center][after] += 1;
        }
    }
    if (p != length or n0 - m0 + f0 != 2 or !connected(&adj, n, -1)) return -1;
    for (0..n) |v| if (!connected(&adj, n, @intCast(v))) return -1;
    for (0..m) |e| if (uses[eu[e]][ev[e]] != 1 or uses[ev[e]][eu[e]] != 1) return -1;
    for (0..n) |center| {
        var start: ?usize = null;
        var incident_count: usize = 0;
        for (0..n) |neighbor| {
            if (adj[center][neighbor]) {
                if (link_degree[center][neighbor] != 2) return -1;
                if (start == null) start = neighbor;
                incident_count += 1;
            } else if (link_degree[center][neighbor] != 0) return -1;
        }
        var seen = [_]bool{false} ** N;
        var stack = [_]usize{0} ** N;
        var top: usize = 1;
        var reached: usize = 0;
        const seed = start orelse return -1;
        seen[seed] = true;
        stack[0] = seed;
        while (top > 0) {
            top -= 1;
            const neighbor = stack[top];
            reached += 1;
            for (0..n) |other| {
                if (link_adj[center][neighbor][other] and !seen[other]) {
                    seen[other] = true;
                    stack[top] = other;
                    top += 1;
                }
            }
        }
        if (reached != incident_count) return -1;
    }
    var fa = [_]usize{0} ** M; var fb = [_]usize{0} ** M; var face_use = [_]usize{0} ** M;
    for (0..f) |g| for (0..width[g]) |i| {
        const u = face[g][i]; const v = face[g][(i + 1) % width[g]];
        const lo = @min(u, v); const hi = @max(u, v); var found: ?usize = null;
        for (0..m) |e| if (eu[e] == lo and ev[e] == hi) { found = e; break; };
        const e = found orelse return -1;
        if (face_use[e] >= 2) return -1;
        if (face_use[e] == 0) { fa[e] = g; } else { fb[e] = g; }
        face_use[e] += 1;
    };
    for (0..m) |e| if (face_use[e] != 2 or fa[e] == fb[e]) return -1;
    const output = output_opt orelse return -2;
    if (capacity < 8) return -2;

    const base = n + f; const source = base; const sink = base + 1; const nodes = base + 2;
    var edges: [MAX_EDGES]Edge = undefined; var edge_count: usize = 0;
    var balance = [_]i64{0} ** (N + F);
    for (0..n) |v| balance[v] = 4;
    for (0..f) |g| {
        const d: i64 = @intCast(width[g]);
        balance[n + g] -= 2 * d + (if (g == outer) @as(i64, 4) else @as(i64, -4));
        for (0..width[g]) |i| {
            const v = face[g][i]; balance[v] -= 1; balance[n + g] += 1;
            if (!addArc(&edges, &edge_count, v, n + g, 4 * @as(i64, @intCast(n)), 0)) return -1;
        }
    }
    for (0..m) |e| {
        if (!addArc(&edges, &edge_count, n + fa[e], n + fb[e], 4 * @as(i64, @intCast(n)), 1) or
            !addArc(&edges, &edge_count, n + fb[e], n + fa[e], 4 * @as(i64, @intCast(n)), 1)) return -1;
    }
    var need: i64 = 0;
    for (0..base) |v| {
        if (balance[v] > 0) { if (!addArc(&edges, &edge_count, source, v, balance[v], 0)) return -1; need += balance[v]; }
        else if (balance[v] < 0 and !addArc(&edges, &edge_count, v, sink, -balance[v], 0)) return -1;
    }
    var potential = [_]i64{0} ** MAX_NODES; var total_flow: i64 = 0; var total_cost: i64 = 0;
    while (total_flow < need) {
        var dist = [_]i64{INF} ** MAX_NODES; var parent = [_]usize{MAX_EDGES} ** MAX_NODES;
        var used = [_]bool{false} ** MAX_NODES; dist[source] = 0;
        for (0..nodes) |_| {
            var chosen: ?usize = null;
            for (0..nodes) |v| if (!used[v] and dist[v] != INF and (chosen == null or dist[v] < dist[chosen.?])) { chosen = v; };
            const u = chosen orelse break; used[u] = true;
            for (0..edge_count) |e| {
                if (edges[e].from != u or edges[e].cap <= 0) continue;
                const v = edges[e].to; const alt = dist[u] + edges[e].cost + potential[u] - potential[v];
                if (!used[v] and alt < dist[v]) { dist[v] = alt; parent[v] = e; }
            }
        }
        if (dist[sink] == INF) return -1;
        for (0..nodes) |v| if (dist[v] != INF) { potential[v] += dist[v]; };
        var amount = need - total_flow; var path_cost: i64 = 0; var v = sink;
        while (v != source) {
            const e = parent[v]; if (e == MAX_EDGES) return -1;
            amount = @min(amount, edges[e].cap); path_cost += edges[e].cost; v = edges[e].from;
        }
        v = sink;
        while (v != source) { const e = parent[v]; const prev = edges[e].from; edges[e].cap -= amount; edges[edges[e].rev].cap += amount; v = prev; }
        total_flow += amount; total_cost += amount * path_cost;
    }
    const bits: u64 = @intCast(total_cost);
    for (0..8) |i| output[i] = @truncate(bits >> @intCast(8 * i));
    return 8;
}
