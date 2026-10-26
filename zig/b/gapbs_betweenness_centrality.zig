// Clean-room bounded Brandes profile; see package LICENSE.txt.
const max_n: usize = 8;

export fn gapbs_betweenness_centrality(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 12 or length > 74) return -1;
    if (input[0] < 3 or input[0] > 8 or input[1] < 1 or input[1] > input[0]) return -1;
    const n: usize = @intCast(input[0]);
    const k: usize = @intCast(input[1]);
    if (length != 2 + k + n * n) return -1;
    var sources = [_]usize{0} ** max_n;
    for (0..k) |i| {
        const raw = input[2 + i];
        if (raw < 0 or raw >= input[0]) return -1;
        sources[i] = @intCast(raw);
        for (0..i) |j| if (sources[j] == sources[i]) return -1;
    }
    var adjacency = [_][max_n]i64{[_]i64{0} ** max_n} ** max_n;
    for (0..n) |u| for (0..n) |v| {
        const edge = input[2 + k + u * n + v];
        if ((edge != 0 and edge != 1) or (u == v and edge != 0)) return -1;
        adjacency[u][v] = edge;
    };
    for (0..n) |u| for (u + 1..n) |v| {
        if (adjacency[u][v] != adjacency[v][u]) return -1;
    };

    var scores = [_]f32{0} ** max_n;
    for (0..k) |si| {
        var depth = [_]i32{-1} ** max_n;
        var queue = [_]usize{0} ** max_n;
        var paths = [_]f64{0} ** max_n;
        var delta = [_]f32{0} ** max_n;
        const source = sources[si];
        depth[source] = 0;
        paths[source] = 1.0;
        var head: usize = 0;
        var tail: usize = 1;
        queue[0] = source;
        while (head < tail) {
            const u = queue[head];
            head += 1;
            for (0..n) |v| {
                if (adjacency[u][v] != 0) {
                    if (depth[v] == -1) {
                        depth[v] = depth[u] + 1;
                        queue[tail] = v;
                        tail += 1;
                    }
                    if (depth[v] == depth[u] + 1) paths[v] += paths[u];
                }
            }
        }
        var max_depth: i32 = 0;
        for (0..n) |v| if (depth[v] > max_depth) { max_depth = depth[v]; };
        var d = max_depth;
        while (d >= 0) : (d -= 1) {
            for (0..n) |u| if (depth[u] == d) {
                var delta_u: f32 = 0.0;
                for (0..n) |v| {
                    if (adjacency[u][v] != 0 and depth[v] == d + 1) {
                        const one_plus: f32 = 1.0 + delta[v];
                        const contribution = (paths[u] / paths[v]) * @as(f64, one_plus);
                        delta_u = @floatCast(@as(f64, delta_u) + contribution);
                    }
                }
                delta[u] = delta_u;
                scores[u] = @floatCast(@as(f64, scores[u]) + @as(f64, delta_u));
            };
        }
    }
    var biggest: f32 = 0.0;
    for (0..n) |v| if (scores[v] > biggest) { biggest = scores[v]; };
    if (!(biggest > 0.0)) return -1;
    var checksum: i64 = 0;
    for (0..n) |v| {
        const normalized: f32 = scores[v] / biggest;
        const qscore: i64 = @intFromFloat(@as(f64, normalized) * 1000.0 + 0.5);
        checksum += @as(i64, @intCast(v + 1)) * qscore;
    }
    return checksum;
}
