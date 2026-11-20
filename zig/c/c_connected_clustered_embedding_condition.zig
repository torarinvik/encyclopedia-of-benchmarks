const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const INPUT_MAX: usize = 55;

const Graph = struct {
    n: usize = 0,
    c: usize = 0,
    m: usize = 0,
    f: usize = 0,
    outer_u: usize = 0,
    outer_v: usize = 0,
    outer_face: usize = 0,
    degree: [N]usize = [_]usize{0} ** N,
    mask: [N]usize = [_]usize{0} ** N,
    edge_u: [M]usize = [_]usize{0} ** M,
    edge_v: [M]usize = [_]usize{0} ** M,
    rotation: [N][N]usize = [_][N]usize{[_]usize{0} ** N} ** N,
    face_of: [N][N]i32 = [_][N]i32{[_]i32{-1} ** N} ** N,
    adjacent: [N][N]bool = [_][N]bool{[_]bool{false} ** N} ** N,
};

fn root(parent: *[F]usize, x0: usize) usize {
    var x = x0;
    while (parent[x] != x) {
        parent[x] = parent[parent[x]];
        x = parent[x];
    }
    return x;
}

fn connected(g: *const Graph, mask: usize) bool {
    var start: ?usize = null;
    var expected: usize = 0;
    for (0..g.n) |v| {
        if ((mask >> @intCast(v)) & 1 != 0) {
            if (start == null) start = v;
            expected += 1;
        }
    }
    if (expected <= 1) return true;
    var seen = [_]bool{false} ** N;
    var queue = [_]usize{0} ** N;
    var head: usize = 0;
    var tail: usize = 1;
    queue[0] = start.?;
    seen[start.?] = true;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..g.n) |v| {
            if ((mask >> @intCast(v)) & 1 != 0 and g.adjacent[u][v] and !seen[v]) {
                seen[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    return tail == expected;
}

fn parse(input: [*]const i64, length: usize) ?Graph {
    if (length < 4 or length > INPUT_MAX) return null;
    if (input[0] < 3 or input[0] > N or input[1] < 0 or input[1] > input[0] - 2) return null;
    var g = Graph{};
    g.n = @intCast(input[0]);
    g.c = @intCast(input[1]);
    if (input[2] < 0 or input[2] >= input[0] or input[3] < 0 or input[3] >= input[0] or input[2] == input[3]) return null;
    g.outer_u = @intCast(input[2]);
    g.outer_v = @intCast(input[3]);
    var offset: usize = 4;
    var degree_sum: usize = 0;
    for (0..g.n) |u| {
        if (offset >= length) return null;
        const d_raw = input[offset];
        offset += 1;
        if (d_raw < 1 or d_raw >= input[0] or offset + @as(usize, @intCast(d_raw)) > length) return null;
        const d: usize = @intCast(d_raw);
        g.degree[u] = d;
        degree_sum += d;
        var row_seen = [_]bool{false} ** N;
        for (0..d) |i| {
            const v_raw = input[offset];
            offset += 1;
            if (v_raw < 0 or v_raw >= input[0] or v_raw == @as(i64, @intCast(u))) return null;
            const v: usize = @intCast(v_raw);
            if (row_seen[v]) return null;
            row_seen[v] = true;
            g.rotation[u][i] = v;
            g.adjacent[u][v] = true;
        }
    }
    if (degree_sum % 2 != 0 or offset + g.c != length) return null;
    g.m = degree_sum / 2;
    if (g.m < g.n - 1 or g.m > M or !g.adjacent[g.outer_u][g.outer_v]) return null;
    var edge_count: usize = 0;
    for (0..g.n) |u| {
        for (0..g.n) |v| {
            if (g.adjacent[u][v] != g.adjacent[v][u]) return null;
            if (u < v and g.adjacent[u][v]) {
                g.edge_u[edge_count] = u;
                g.edge_v[edge_count] = v;
                edge_count += 1;
            }
        }
    }
    if (edge_count != g.m) return null;
    const full = (@as(usize, 1) << @intCast(g.n)) - 1;
    for (0..g.c) |i| {
        const raw = input[offset + i];
        if (raw <= 0 or raw >= @as(i64, @intCast(full))) return null;
        const mask: usize = @intCast(raw);
        if (@popCount(mask) < 2) return null;
        for (0..i) |j| {
            if (g.mask[j] == mask) return null;
            const overlap = g.mask[j] & mask;
            if (overlap != 0 and overlap != g.mask[j] and overlap != mask) return null;
        }
        g.mask[i] = mask;
        if (!connected(&g, mask)) return null;
    }
    if (!connected(&g, full)) return null;

    g.f = 0;
    for (0..g.m) |e| {
        for (0..2) |side| {
            const su = if (side == 0) g.edge_u[e] else g.edge_v[e];
            const sv = if (side == 0) g.edge_v[e] else g.edge_u[e];
            if (g.face_of[su][sv] >= 0) continue;
            if (g.f >= F) return null;
            var local = [_][N]bool{[_]bool{false} ** N} ** N;
            var u = su;
            var v = sv;
            var steps: usize = 0;
            while (true) {
                if (local[u][v] or g.face_of[u][v] >= 0) return null;
                local[u][v] = true;
                g.face_of[u][v] = @intCast(g.f);
                var at: ?usize = null;
                for (0..g.degree[v]) |i| if (g.rotation[v][i] == u) { at = i; break; };
                if (at == null) return null;
                const next = g.rotation[v][(at.? + 1) % g.degree[v]];
                u = v;
                v = next;
                if (u == su and v == sv) break;
                steps += 1;
                if (steps > 2 * g.m) return null;
            }
            g.f += 1;
        }
    }
    if (g.f != g.m - g.n + 2) return null;
    for (0..g.n) |u| for (0..g.n) |v| {
        if (g.adjacent[u][v] and g.face_of[u][v] < 0) return null;
    };
    g.outer_face = @intCast(g.face_of[g.outer_u][g.outer_v]);
    return g;
}

fn solve(g: *const Graph) i64 {
    for (0..g.c) |ci| {
        const mask = g.mask[ci];
        var parent = [_]usize{0} ** F;
        for (0..g.f) |f| parent[f] = f;
        for (0..g.m) |e| {
            const u = g.edge_u[e];
            const v = g.edge_v[e];
            if ((mask >> @intCast(u)) & 1 != 0 and (mask >> @intCast(v)) & 1 != 0) continue;
            const a = root(&parent, @intCast(g.face_of[u][v]));
            const b = root(&parent, @intCast(g.face_of[v][u]));
            parent[a] = b;
        }
        const outside = root(&parent, g.outer_face);
        for (0..g.n) |v| {
            if ((mask >> @intCast(v)) & 1 != 0) continue;
            var incident = false;
            for (0..g.n) |u| {
                if (g.adjacent[v][u]) {
                    incident = true;
                    if (root(&parent, @intCast(g.face_of[v][u])) != outside) return 0;
                }
            }
            if (!incident) return -1;
        }
        for (0..g.m) |e| {
            const u = g.edge_u[e];
            const v = g.edge_v[e];
            if ((mask >> @intCast(u)) & 1 != 0 and (mask >> @intCast(v)) & 1 != 0) continue;
            if (root(&parent, @intCast(g.face_of[u][v])) != outside) return 0;
        }
    }
    return 1;
}

export fn c_connected_clustered_embedding_condition(input_opt: ?[*]const i64, length: usize) i64 {
    const input = input_opt orelse return -1;
    if (length < 4 or length > INPUT_MAX) return -1;
    const g = parse(input, length) orelse return -1;
    return solve(&g);
}
