const std = @import("std");

const MAX_N: usize = 8;
const MAX_EDGES: usize = 18;
const MAX_FACES: usize = 16;
const MAX_DARTS: usize = 2 * (MAX_N - 1);
const MAX_STACK: usize = 64;
const MAX_INPUT: usize = 55;

const Dart = struct { u: usize, v: usize };
const Triple = struct { a: usize, b: usize, c: usize };

const State = struct {
    x: [MAX_N]i64,
    y: [MAX_N]i64,
    edge_u: [MAX_EDGES]usize,
    edge_v: [MAX_EDGES]usize,
    edge_count: usize,
    face_a: [MAX_FACES]usize,
    face_b: [MAX_FACES]usize,
    face_c: [MAX_FACES]usize,
    face_count: usize,
    rotation: [MAX_N][MAX_N]usize,
    degree: [MAX_N]usize,
    tree_rotation: [MAX_N][MAX_N]usize,
    tree_degree: [MAX_N]usize,
    contour: [MAX_DARTS]Dart,
    contour_len: usize,
    stack: [MAX_STACK]Dart,
    stack_len: usize,
    weight: [MAX_N][MAX_N]f64,
    hull: [MAX_N]bool,
    tree: [MAX_N][MAX_N]bool,
    kept: [MAX_N][MAX_N]bool,
};

fn orient(s: *const State, a: usize, b: usize, c: usize) i64 {
    return (s.x[b] - s.x[a]) * (s.y[c] - s.y[a]) - (s.y[b] - s.y[a]) * (s.x[c] - s.x[a]);
}

fn incircle(s: *const State, a: usize, b: usize, c: usize, p: usize) i64 {
    const ax = s.x[a] - s.x[p];
    const ay = s.y[a] - s.y[p];
    const bx = s.x[b] - s.x[p];
    const by = s.y[b] - s.y[p];
    const cx = s.x[c] - s.x[p];
    const cy = s.y[c] - s.y[p];
    const det = (ax * ax + ay * ay) * (bx * cy - by * cx)
        - (bx * bx + by * by) * (ax * cy - ay * cx)
        + (cx * cx + cy * cy) * (ax * by - ay * bx);
    return if (orient(s, a, b, c) > 0) det else -det;
}

fn dist2(s: *const State, a: usize, b: usize) i64 {
    const dx = s.x[a] - s.x[b];
    const dy = s.y[a] - s.y[b];
    return dx * dx + dy * dy;
}

fn sort3(a0: usize, b0: usize, c0: usize) Triple {
    var a = a0;
    var b = b0;
    var c = c0;
    if (a > b) { const t = a; a = b; b = t; }
    if (b > c) { const t = b; b = c; c = t; }
    if (a > b) { const t = a; a = b; b = t; }
    return .{ .a = a, .b = b, .c = c };
}

fn isFace(s: *const State, a0: usize, b0: usize, c0: usize) bool {
    const t = sort3(a0, b0, c0);
    for (0..s.face_count) |i| {
        if (s.face_a[i] == t.a and s.face_b[i] == t.b and s.face_c[i] == t.c) return true;
    }
    return false;
}

fn angleLess(s: *const State, origin: usize, a: usize, b: usize) bool {
    const ax = s.x[a] - s.x[origin];
    const ay = s.y[a] - s.y[origin];
    const bx = s.x[b] - s.x[origin];
    const by = s.y[b] - s.y[origin];
    const ah: u8 = if (ay > 0 or (ay == 0 and ax >= 0)) 0 else 1;
    const bh: u8 = if (by > 0 or (by == 0 and bx >= 0)) 0 else 1;
    if (ah != bh) return ah < bh;
    const cross = ax * by - ay * bx;
    if (cross != 0) return cross > 0;
    return a < b;
}

fn sortNeighbors(s: *const State, row: *[MAX_N]usize, count: usize, origin: usize) void {
    for (1..count) |i| {
        const key = row[i];
        var j = i;
        while (j > 0 and angleLess(s, origin, key, row[j - 1])) : (j -= 1) {
            row[j] = row[j - 1];
        }
        row[j] = key;
    }
}

fn cwNext(s: *const State, u: usize, v: usize) ?Dart {
    for (0..s.degree[v]) |i| {
        if (s.rotation[v][i] == u) return .{ .u = v, .v = s.rotation[v][(i + s.degree[v] - 1) % s.degree[v]] };
    }
    return null;
}

fn cwTreeNext(s: *const State, u: usize, v: usize) ?Dart {
    for (0..s.tree_degree[v]) |i| {
        if (s.tree_rotation[v][i] == u) return .{ .u = v, .v = s.tree_rotation[v][(i + s.tree_degree[v] - 1) % s.tree_degree[v]] };
    }
    return null;
}

fn contourFind(s: *const State, u: usize, v: usize) ?usize {
    for (0..s.contour_len) |i| if (s.contour[i].u == u and s.contour[i].v == v) return i;
    return null;
}

fn canonicalize(s: *State) void {
    if (s.contour_len == 0) return;
    var first: usize = 0;
    for (1..s.contour_len) |i| {
        if (s.contour[i].u < s.contour[first].u or (s.contour[i].u == s.contour[first].u and s.contour[i].v < s.contour[first].v)) first = i;
    }
    var rotated: [MAX_DARTS]Dart = std.mem.zeroes([MAX_DARTS]Dart);
    for (0..s.contour_len) |i| rotated[i] = s.contour[(first + i) % s.contour_len];
    s.contour = rotated;
}

fn eligible(s: *const State, u: usize, v: usize) bool {
    const at = contourFind(s, u, v) orelse return false;
    if (s.hull[v] or s.contour_len < 3) return false;
    const next = (at + 1) % s.contour_len;
    const cw = cwNext(s, u, v) orelse return false;
    return s.contour[next].u == cw.u and s.contour[next].v == cw.v and isFace(s, u, v, cw.v);
}

fn pushCandidate(s: *State, u: usize, v: usize) bool {
    if (!eligible(s, u, v)) return true;
    if (s.stack_len >= MAX_STACK) return false;
    s.stack[s.stack_len] = .{ .u = u, .v = v };
    s.stack_len += 1;
    return true;
}

fn parse(s: *State, input: []const i64) ?usize {
    if (input.len < 14 or input.len > MAX_INPUT) return null;
    if (input[0] < 3 or input[0] > @as(i64, @intCast(MAX_N))) return null;
    const n: usize = @intCast(input[0]);
    const m_at = 1 + 2 * n;
    if (input.len <= m_at or input[m_at] < 3 or input[m_at] > @as(i64, @intCast(MAX_EDGES))) return null;
    const m: usize = @intCast(input[m_at]);
    if (input.len != m_at + 1 + 2 * m) return null;
    for (0..n) |i| {
        s.x[i] = input[1 + 2 * i];
        s.y[i] = input[2 + 2 * i];
        if (s.x[i] < -10 or s.x[i] > 10 or s.y[i] < -10 or s.y[i] > 10) return null;
        for (0..i) |j| if (s.x[i] == s.x[j] and s.y[i] == s.y[j]) return null;
    }
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        if (orient(s, a, b, c) == 0) return null;
    };
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| for (c + 1..n) |d| {
        if (incircle(s, a, b, c, d) == 0) return null;
    };
    s.edge_count = m;
    var supplied: [MAX_N][MAX_N]bool = @splat(@splat(false));
    for (0..m) |i| {
        const u_raw = input[m_at + 1 + 2 * i];
        const v_raw = input[m_at + 2 + 2 * i];
        if (u_raw < 0 or v_raw <= u_raw or v_raw >= @as(i64, @intCast(n))) return null;
        const u: usize = @intCast(u_raw);
        const v: usize = @intCast(v_raw);
        if (i > 0 and (u < s.edge_u[i - 1] or (u == s.edge_u[i - 1] and v <= s.edge_v[i - 1]))) return null;
        s.edge_u[i] = u;
        s.edge_v[i] = v;
        supplied[u][v] = true;
        supplied[v][u] = true;
    }
    var expected: [MAX_N][MAX_N]bool = @splat(@splat(false));
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        var tri = [3]usize{ a, b, c };
        if (orient(s, tri[0], tri[1], tri[2]) < 0) { const t = tri[1]; tri[1] = tri[2]; tri[2] = t; }
        var empty = true;
        for (0..n) |p| {
            if (p != tri[0] and p != tri[1] and p != tri[2] and incircle(s, tri[0], tri[1], tri[2], p) > 0) empty = false;
        }
        if (empty) {
            if (s.face_count >= MAX_FACES) return null;
            const t = sort3(a, b, c);
            s.face_a[s.face_count] = t.a;
            s.face_b[s.face_count] = t.b;
            s.face_c[s.face_count] = t.c;
            s.face_count += 1;
            expected[a][b] = true; expected[b][a] = true;
            expected[b][c] = true; expected[c][b] = true;
            expected[a][c] = true; expected[c][a] = true;
        }
    };
    for (0..n) |a| for (a + 1..n) |b| if (supplied[a][b] != expected[a][b]) return null;
    for (0..n) |a| for (a + 1..n) |b| {
        var positive = false;
        var negative = false;
        for (0..n) |p| {
            if (p != a and p != b) {
                const side = orient(s, a, b, p);
                positive = positive or side > 0;
                negative = negative or side < 0;
            }
        }
        if (!(positive and negative)) { s.hull[a] = true; s.hull[b] = true; }
    };
    for (0..m) |i| {
        const u = s.edge_u[i];
        const v = s.edge_v[i];
        s.rotation[u][s.degree[u]] = v; s.degree[u] += 1;
        s.rotation[v][s.degree[v]] = u; s.degree[v] += 1;
    }
    for (0..n) |v| sortNeighbors(s, &s.rotation[v], s.degree[v], v);
    return n;
}

fn buildMstContour(s: *State, n: usize) bool {
    var order: [MAX_EDGES]usize = @splat(0);
    for (0..s.edge_count) |i| order[i] = i;
    for (1..s.edge_count) |i| {
        const key = order[i];
        var j = i;
        while (j > 0) {
            const prev = order[j - 1];
            const pl = dist2(s, s.edge_u[prev], s.edge_v[prev]);
            const kl = dist2(s, s.edge_u[key], s.edge_v[key]);
            if (pl < kl or (pl == kl and (s.edge_u[prev] < s.edge_u[key] or (s.edge_u[prev] == s.edge_u[key] and s.edge_v[prev] <= s.edge_v[key])))) break;
            order[j] = prev;
            j -= 1;
        }
        order[j] = key;
    }
    var parent: [MAX_N]usize = @splat(0);
    var size: [MAX_N]usize = @splat(1);
    for (0..n) |i| parent[i] = i;
    var chosen: usize = 0;
    for (0..s.edge_count) |rank| {
        const e = order[rank];
        const u = s.edge_u[e]; const v = s.edge_v[e];
        var a = u; var b = v;
        while (parent[a] != a) { parent[a] = parent[parent[a]]; a = parent[a]; }
        while (parent[b] != b) { parent[b] = parent[parent[b]]; b = parent[b]; }
        if (a == b) continue;
        if (size[a] < size[b]) { const t = a; a = b; b = t; }
        parent[b] = a; size[a] += size[b];
        s.tree[u][v] = true; s.tree[v][u] = true;
        s.kept[u][v] = true; s.kept[v][u] = true;
        s.tree_rotation[u][s.tree_degree[u]] = v; s.tree_degree[u] += 1;
        s.tree_rotation[v][s.tree_degree[v]] = u; s.tree_degree[v] += 1;
        chosen += 1;
    }
    if (chosen != n - 1) return false;
    for (0..n) |v| sortNeighbors(s, &s.tree_rotation[v], s.tree_degree[v], v);
    for (0..s.edge_count) |i| {
        const u = s.edge_u[i]; const v = s.edge_v[i];
        const w = @sqrt(@as(f64, @floatFromInt(dist2(s, u, v))));
        s.weight[u][v] = w; s.weight[v][u] = w;
    }
    var first = Dart{ .u = MAX_N, .v = MAX_N };
    for (0..n) |u| for (0..n) |v| {
        if (s.tree[u][v] and (u < first.u or (u == first.u and v < first.v))) first = .{ .u = u, .v = v };
    };
    if (first.u == MAX_N) return false;
    s.contour[0] = first;
    s.contour_len = 1;
    const expected = 2 * (n - 1);
    while (s.contour_len < expected) {
        const last = s.contour[s.contour_len - 1];
        const next = cwTreeNext(s, last.u, last.v) orelse return false;
        if (next.u == first.u and next.v == first.v) break;
        for (0..s.contour_len) |i| if (s.contour[i].u == next.u and s.contour[i].v == next.v) return false;
        s.contour[s.contour_len] = next;
        s.contour_len += 1;
    }
    if (s.contour_len != expected) return false;
    const last = s.contour[s.contour_len - 1];
    const close = cwTreeNext(s, last.u, last.v) orelse return false;
    return close.u == first.u and close.v == first.v;
}

fn runAlgorithm(s: *State, n: usize) ?struct { absorbed: usize, shortcuts: usize } {
    for (0..s.contour_len) |i| if (!pushCandidate(s, s.contour[i].u, s.contour[i].v)) return null;
    var absorbed: usize = 0;
    var steps: usize = 0;
    while (s.stack_len > 0 and steps < 2 * MAX_EDGES) {
        s.stack_len -= 1;
        const dart = s.stack[s.stack_len];
        const v = dart.u; const w = dart.v;
        if (!eligible(s, v, w)) continue;
        const at = contourFind(s, v, w) orelse return null;
        const next_at = (at + 1) % s.contour_len;
        const u = s.contour[next_at].v;
        const path_weight = s.weight[v][w] + s.weight[w][u];
        const chord_length = @sqrt(@as(f64, @floatFromInt(dist2(s, v, u))));
        if (path_weight > 2.0 * chord_length) { s.kept[v][u] = true; s.kept[u][v] = true; }
        else { s.weight[v][u] = path_weight; }
        if (next_at == 0) {
            for (0..s.contour_len - 1) |i| s.contour[i] = s.contour[i + 1];
            s.contour_len -= 1;
            s.contour[s.contour_len - 1] = .{ .u = v, .v = u };
        } else {
            s.contour[at] = .{ .u = v, .v = u };
            for (next_at..s.contour_len - 1) |i| s.contour[i] = s.contour[i + 1];
            s.contour_len -= 1;
        }
        canonicalize(s);
        absorbed += 1; steps += 1;
        const chord_at = contourFind(s, v, u) orelse return null;
        if (!pushCandidate(s, v, u)) return null;
        const left_at = (chord_at + s.contour_len - 1) % s.contour_len;
        const left = s.contour[left_at];
        if (!pushCandidate(s, left.u, left.v)) return null;
    }
    if (steps >= 2 * MAX_EDGES and s.stack_len > 0) return null;
    var shortcuts: usize = 0;
    for (0..n) |u| for (u + 1..n) |v| if (s.kept[u][v] and !s.tree[u][v]) { shortcuts += 1; };
    return .{ .absorbed = absorbed, .shortcuts = shortcuts };
}

export fn levcopoulos_lingas_planar_geometric_spanner(input_opt: ?[*]const i64, length: usize, output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 14 or length > MAX_INPUT) return -1;
    const input = input_opt.?[0..length];
    var state: State = std.mem.zeroes(State);
    const n = parse(&state, input) orelse return -1;
    if (!buildMstContour(&state, n)) return -1;
    const result = runAlgorithm(&state, n) orelse return -1;
    var words: [3 + 2 * MAX_EDGES]i64 = @splat(0);
    words[0] = @intCast(result.absorbed);
    words[1] = @intCast(result.shortcuts);
    var count: usize = 3;
    for (0..n) |u| for (u + 1..n) |v| {
        if (state.kept[u][v]) {
            words[count] = @intCast(u);
            words[count + 1] = @intCast(v);
            words[2] += 1;
            count += 2;
        }
    };
    const output_bytes = count * 8;
    if (output_opt == null or capacity < output_bytes) return -2;
    const output = output_opt.?;
    for (0..count) |i| {
        const bits: u64 = @bitCast(words[i]);
        for (0..8) |byte| {
            const shift: u6 = @intCast(byte * 8);
            output[i * 8 + byte] = @truncate(bits >> shift);
        }
    }
    return @intCast(output_bytes);
}
