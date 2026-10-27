const N: usize = 8;
const MAX_M: usize = 28;
const MAX_OUT: usize = 81;

fn ancestor(parent: [N][N]i32, source: usize, a: usize, target: usize) bool {
    var v: i32 = @intCast(target);
    while (v >= 0) {
        if (@as(usize, @intCast(v)) == a) return true;
        if (@as(usize, @intCast(v)) == source) break;
        v = parent[source][@intCast(v)];
    }
    return false;
}
fn putI64(out: [*c]u8, pos: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| out[pos + b] = @truncate(bits >> @intCast(8 * b));
}

export fn hub_labeling_greedy_order(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length < 2 or length > 58) return -1;
    const n0 = input[0]; const m0 = input[1];
    if (n0 < 1 or n0 > N or m0 < 0 or m0 > n0 * (n0 - 1) / 2 or length != 2 + 2 * @as(usize, @intCast(m0))) return -1;
    const n: usize = @intCast(n0); const m: usize = @intCast(m0);
    var adj = [_][N]bool{[_]bool{false} ** N} ** N;
    var prev_u: i64 = -1; var prev_v: i64 = -1;
    for (0..m) |e| {
        const u = input[2 + 2 * e]; const v = input[3 + 2 * e];
        if (u < 0 or v <= u or v >= n0 or (e > 0 and (u < prev_u or (u == prev_u and v <= prev_v))) return -1;
        adj[@intCast(u)][@intCast(v)] = true; adj[@intCast(v)][@intCast(u)] = true; prev_u = u; prev_v = v;
    }
    var parent = [_][N]i32{[_]i32{-1} ** N} ** N;
    var depth = [_][N]i32{[_]i32{-1} ** N} ** N;
    var ways = [_][N]u8{[_]u8{0} ** N} ** N;
    for (0..n) |s| {
        var queue = [_]usize{0} ** N; var head: usize = 0; var tail: usize = 0;
        queue[tail] = s; tail += 1; depth[s][s] = 0; ways[s][s] = 1;
        while (head < tail) {
            const u = queue[head]; head += 1;
            for (0..n) |v| if (adj[u][v]) {
                if (depth[s][v] < 0) {
                    depth[s][v] = depth[s][u] + 1; parent[s][v] = @intCast(u); ways[s][v] = ways[s][u]; queue[tail] = v; tail += 1;
                } else if (depth[s][v] == depth[s][u] + 1) {
                    ways[s][v] = @intCast(@min(2, @as(u16, ways[s][v]) + ways[s][u]));
                }
            };
        }
        for (0..n) |v| if (depth[s][v] < 0 or ways[s][v] != 1) return -1;
    }
    var active = [_][N]bool{[_]bool{true} ** N} ** N;
    var order = [_]usize{0} ** N; var rank = [_]usize{0} ** N;
    for (0..n) |turn| {
        var counts = [_]usize{0} ** N;
        for (0..n) |s| for (0..n) |t| if (active[s][t]) {
            var v: i32 = @intCast(t);
            while (v >= 0) { counts[@intCast(v)] += 1; if (@as(usize, @intCast(v)) == s) break; v = parent[s][@intCast(v)]; }
        };
        var best: usize = 0;
        for (1..n) |v| if (counts[v] > counts[best]) { best = v; };
        order[turn] = best; rank[best] = turn;
        for (0..n) |s| for (0..n) |t| if (active[s][t] and ancestor(parent, s, best, t)) { active[s][t] = false; };
    }
    var has = [_][N]bool{[_]bool{false} ** N} ** N;
    var label_dist = [_][N]i32{[_]i32{0} ** N} ** N;
    for (0..n) |u| for (u..n) |v| {
        var path = [_]usize{0} ** N; var path_len: usize = 0; var x: i32 = @intCast(v);
        while (x >= 0) { path[path_len] = @intCast(x); path_len += 1; if (@as(usize, @intCast(x)) == u) break; x = parent[u][@intCast(x)]; }
        if (x < 0) return -1;
        var hub = path[0]; for (1..path_len) |i| if (rank[path[i]] < rank[hub]) { hub = path[i]; };
        has[u][hub] = true; has[v][hub] = true; label_dist[u][hub] = depth[u][hub]; label_dist[v][hub] = depth[v][hub];
    };
    var staged = [_]i64{0} ** MAX_OUT; var used: usize = 0;
    staged[used] = @intCast(n); used += 1;
    for (0..n) |i| { staged[used] = @intCast(order[i]); used += 1; }
    for (0..n) |v| {
        var count: i64 = 0; for (0..n) |h| { if (has[v][h]) count += 1; }
        staged[used] = count; used += 1;
        for (0..n) |h| if (has[v][h]) { staged[used] = @as(i64, @intCast(h)) | (@as(i64, label_dist[v][h]) << 8); used += 1; };
    }
    const required = used * 8;
    if (output == null or capacity < required) return -2;
    for (0..used) |i| putI64(output, i * 8, staged[i]);
    return @intCast(required);
}
