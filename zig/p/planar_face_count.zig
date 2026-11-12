const MAX_N: usize = 16;
const MAX_M: usize = 42;
const MAX_INPUT: usize = 118;
const MAX_COORD: i64 = 100;

fn orient(x: []const i64, y: []const i64, a: usize, b: usize, c: usize) i64 {
    return (x[b] - x[a]) * (y[c] - y[a]) - (y[b] - y[a]) * (x[c] - x[a]);
}
fn between(a: i64, b: i64, p: i64) bool { return (a <= p and p <= b) or (b <= p and p <= a); }
fn onSegment(x: []const i64, y: []const i64, a: usize, b: usize, p: usize) bool {
    return between(x[a], x[b], x[p]) and between(y[a], y[b], y[p]);
}
fn intersects(x: []const i64, y: []const i64, a: usize, b: usize, c: usize, d: usize) bool {
    const ab_c = orient(x,y,a,b,c); const ab_d = orient(x,y,a,b,d);
    const cd_a = orient(x,y,c,d,a); const cd_b = orient(x,y,c,d,b);
    if (((ab_c > 0 and ab_d < 0) or (ab_c < 0 and ab_d > 0)) and
        ((cd_a > 0 and cd_b < 0) or (cd_a < 0 and cd_b > 0))) return true;
    return (ab_c == 0 and onSegment(x,y,a,b,c)) or (ab_d == 0 and onSegment(x,y,a,b,d)) or
        (cd_a == 0 and onSegment(x,y,c,d,a)) or (cd_b == 0 and onSegment(x,y,c,d,b));
}
fn half(dx: i64, dy: i64) i32 { return if (dy > 0 or (dy == 0 and dx >= 0)) 0 else 1; }
fn angleLess(a: usize, b: usize, origin: usize, x: []const i64, y: []const i64) bool {
    const ax = x[a] - x[origin]; const ay = y[a] - y[origin];
    const bx = x[b] - x[origin]; const by = y[b] - y[origin];
    const ah = half(ax, ay); const bh = half(bx, by);
    return ah < bh or (ah == bh and ax * by - ay * bx > 0);
}

export fn planar_face_count(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 1 or input[0] > @as(i64, @intCast(MAX_N)) or
        input[1] < 0 or input[1] > @as(i64, @intCast(MAX_M))) return -1;
    const n: usize = @intCast(input[0]); const m: usize = @intCast(input[1]);
    const n_i64: i64 = @intCast(n);
    const edge_cap: usize = if (n == 1) 0 else if (n == 2) 1 else 3 * n - 6;
    if (m > edge_cap or length != 2 + 2 * n + 2 * m) return -1;
    var x = [_]i64{0} ** MAX_N; var y = [_]i64{0} ** MAX_N;
    for (0..n) |v| {
        x[v] = input[2 + 2 * v]; y[v] = input[3 + 2 * v];
        if (x[v] < -MAX_COORD or x[v] > MAX_COORD or y[v] < -MAX_COORD or y[v] > MAX_COORD) return -1;
        for (0..v) |prior| if (x[v] == x[prior] and y[v] == y[prior]) { return -1; };
    }
    var adjacent = [_]bool{false} ** (MAX_N * MAX_N);
    var neighbors = [_]usize{0} ** (MAX_N * MAX_N);
    var degree = [_]usize{0} ** MAX_N;
    var edge_u = [_]usize{0} ** MAX_M; var edge_v = [_]usize{0} ** MAX_M;
    const offset = 2 + 2 * n;
    for (0..m) |e| {
        const u0 = input[offset + 2 * e]; const v0 = input[offset + 2 * e + 1];
        if (u0 < 0 or u0 >= n_i64 or v0 < 0 or v0 >= n_i64 or u0 == v0) return -1;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        if (adjacent[u * MAX_N + v]) return -1;
        adjacent[u * MAX_N + v] = true; adjacent[v * MAX_N + u] = true;
        neighbors[u * MAX_N + degree[u]] = v; degree[u] += 1;
        neighbors[v * MAX_N + degree[v]] = u; degree[v] += 1;
        edge_u[e] = u; edge_v[e] = v;
    }
    var reached = [_]bool{false} ** MAX_N; var queue = [_]usize{0} ** MAX_N;
    var head: usize = 0; var tail: usize = 1; reached[0] = true; queue[0] = 0;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..n) |v| if (adjacent[u * MAX_N + v] and !reached[v]) {
            reached[v] = true; queue[tail] = v; tail += 1;
        };
    }
    for (0..n) |v| if (!reached[v]) { return -1; };
    for (0..m) |i| for (i + 1..m) |j| {
        const u = edge_u[i]; const v = edge_v[i]; const a = edge_u[j]; const b = edge_v[j];
        var common: ?usize = null;
        if (u == a or u == b) common = u else if (v == a or v == b) common = v;
        if (common) |c| {
            const p = if (u == c) v else u; const q = if (a == c) b else a;
            const ax = x[p] - x[c]; const ay = y[p] - y[c];
            const bx = x[q] - x[c]; const by = y[q] - y[c];
            if (ax * by == ay * bx and ax * bx + ay * by > 0) return -1;
        } else if (intersects(x[0..], y[0..], u, v, a, b)) return -1;
    };
    if (n == 1) return 1;
    for (0..n) |u| for (1..degree[u]) |i| {
        const key = neighbors[u * MAX_N + i]; var j = i;
        while (j > 0 and angleLess(key, neighbors[u * MAX_N + j - 1], u, x[0..], y[0..])) {
            neighbors[u * MAX_N + j] = neighbors[u * MAX_N + j - 1]; j -= 1;
        }
        neighbors[u * MAX_N + j] = key;
    };
    var used = [_]bool{false} ** (MAX_N * MAX_N); var faces: i64 = 0;
    for (0..m) |e| for (0..2) |direction| {
        var u = if (direction == 0) edge_u[e] else edge_v[e];
        var v = if (direction == 0) edge_v[e] else edge_u[e];
        if (used[u * MAX_N + v]) continue;
        faces += 1; var steps: usize = 0;
        while (!used[u * MAX_N + v]) {
            used[u * MAX_N + v] = true;
            var reverse: ?usize = null;
            for (0..degree[v]) |i| if (neighbors[v * MAX_N + i] == u) { reverse = i; };
            if (reverse == null or degree[v] == 0) return -1;
            const next = neighbors[v * MAX_N + ((reverse.? + 1) % degree[v])];
            u = v; v = next; steps += 1;
            if (steps > 2 * m) return -1;
        }
    };
    return faces;
}
