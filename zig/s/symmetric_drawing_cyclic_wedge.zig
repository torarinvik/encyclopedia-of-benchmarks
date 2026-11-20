const N: usize = 8;
const M: usize = 18;
const F: usize = 12;
const INPUT_MAX: usize = 55;
const OUTPUT_MAX: usize = 128;

const Graph = struct {
    n: usize = 0, k: usize = 0, b: usize = 0, m: usize = 0, f: usize = 0,
    center: usize = 0, outer_id: usize = 0,
    outer: [N]usize = [_]usize{0} ** N,
    degree: [N]usize = [_]usize{0} ** N,
    rotation: [N][N]usize = [_][N]usize{[_]usize{0} ** N} ** N,
    permutation: [N]usize = [_]usize{0} ** N,
    adjacent: [N][N]bool = [_][N]bool{[_]bool{false} ** N} ** N,
    edge_u: [M]usize = [_]usize{0} ** M,
    edge_v: [M]usize = [_]usize{0} ** M,
    face_len: [F]usize = [_]usize{0} ** F,
    face: [F][N]usize = [_][N]usize{[_]usize{0} ** N} ** F,
    dart_face: [N][N]i32 = [_][N]i32{[_]i32{-1} ** N} ** N,
};

fn connectedWithout(g: *const Graph, removed_a: i32, removed_b: i32) bool {
    var expected: usize = 0;
    var start: usize = 0;
    var has_start = false;
    for (0..g.n) |v| {
        if (@as(i32, @intCast(v)) == removed_a or @as(i32, @intCast(v)) == removed_b) continue;
        expected += 1;
        if (!has_start) { start = v; has_start = true; }
    }
    if (expected <= 1) return true;
    var seen = [_]bool{false} ** N;
    var stack = [_]usize{0} ** N;
    var top: usize = 1;
    var count: usize = 0;
    seen[start] = true;
    stack[0] = start;
    while (top > 0) {
        top -= 1;
        const u = stack[top];
        count += 1;
        for (0..g.n) |v| {
            if (@as(i32, @intCast(v)) != removed_a and @as(i32, @intCast(v)) != removed_b and
                g.adjacent[u][v] and !seen[v]) {
                seen[v] = true;
                stack[top] = v;
                top += 1;
            }
        }
    }
    return count == expected;
}

fn faceWalk(g: *const Graph, first: usize, second: usize, cycle: *[2 * M]usize) ?usize {
    var seen = [_][N]bool{[_]bool{false} ** N} ** N;
    const start_u = first;
    const start_v = second;
    var u = first;
    var v = second;
    var length: usize = 0;
    for (0..2 * g.m) |_| {
        if (!g.adjacent[u][v] or seen[u][v]) return null;
        seen[u][v] = true;
        cycle[length] = u;
        length += 1;
        var at: ?usize = null;
        for (0..g.degree[v]) |i| if (g.rotation[v][i] == u) { at = i; break; };
        const index = at orelse return null;
        const next = g.rotation[v][(index + 1) % g.degree[v]];
        u = v;
        v = next;
        if (u == start_u and v == start_v) return length;
    }
    return null;
}

fn cyclicEqual(a: []const usize, b: []const usize) bool {
    if (a.len != b.len) return false;
    for (0..b.len) |shift| {
        var equal = true;
        for (0..a.len) |i| if (a[i] != b[(i + shift) % b.len]) { equal = false; break; };
        if (equal) return true;
    }
    return false;
}

fn parse(input: [*]const i64, length: usize) ?Graph {
    if (length < 3 or length > INPUT_MAX) return null;
    if (input[0] < 4 or input[0] > N or input[1] < 3 or input[1] > N or
        @mod(input[0] - 1, input[1]) != 0 or
        input[2] < input[1] or input[2] > input[0] or @mod(input[2], input[1]) != 0) return null;
    var g = Graph{};
    g.n = @intCast(input[0]);
    g.k = @intCast(input[1]);
    g.b = @intCast(input[2]);
    var offset: usize = 3;
    if (offset + g.b > length) return null;
    var outer_seen = [_]bool{false} ** N;
    for (0..g.b) |i| {
        const raw = input[offset];
        offset += 1;
        if (raw < 0 or raw >= input[0]) return null;
        const v: usize = @intCast(raw);
        if (outer_seen[v]) return null;
        outer_seen[v] = true;
        g.outer[i] = v;
    }
    var degree_sum: usize = 0;
    for (0..g.n) |u| {
        if (offset >= length) return null;
        const raw_degree = input[offset];
        offset += 1;
        if (raw_degree < 3 or raw_degree >= input[0]) return null;
        const d: usize = @intCast(raw_degree);
        if (offset + d > length) return null;
        g.degree[u] = d;
        degree_sum += d;
        var row_seen = [_]bool{false} ** N;
        for (0..d) |i| {
            const raw = input[offset];
            offset += 1;
            if (raw < 0 or raw >= input[0] or raw == @as(i64, @intCast(u))) return null;
            const v: usize = @intCast(raw);
            if (row_seen[v]) return null;
            row_seen[v] = true;
            g.rotation[u][i] = v;
            g.adjacent[u][v] = true;
        }
    }
    if (offset + g.n != length or degree_sum % 2 != 0) return null;
    var perm_seen = [_]bool{false} ** N;
    for (0..g.n) |u| {
        const raw = input[offset + u];
        if (raw < 0 or raw >= input[0]) return null;
        const v: usize = @intCast(raw);
        if (perm_seen[v]) return null;
        perm_seen[v] = true;
        g.permutation[u] = v;
    }
    g.m = degree_sum / 2;
    if (g.m < g.n or g.m > 3 * g.n - 6 or g.m > M) return null;
    var edge_count: usize = 0;
    for (0..g.n) |u| for (0..g.n) |v| {
        if (g.adjacent[u][v] != g.adjacent[v][u]) return null;
        if (u < v and g.adjacent[u][v]) {
            g.edge_u[edge_count] = u;
            g.edge_v[edge_count] = v;
            edge_count += 1;
        }
    };
    if (edge_count != g.m or !connectedWithout(&g, -1, -1)) return null;
    for (0..g.n) |u| {
        if (!connectedWithout(&g, @intCast(u), -1)) return null;
        for (u + 1..g.n) |v| if (!connectedWithout(&g, @intCast(u), @intCast(v))) return null;
    }
    for (0..g.m) |e| {
        const ends = [_][2]usize{.{ g.edge_u[e], g.edge_v[e] }, .{ g.edge_v[e], g.edge_u[e] }};
        for (ends) |dart| {
            const u = dart[0];
            const v = dart[1];
            if (g.dart_face[u][v] >= 0) continue;
            if (g.f >= F) return null;
            var cycle = [_]usize{0} ** (2 * M);
            const length_face = faceWalk(&g, u, v, &cycle) orelse return null;
            if (length_face < 3 or length_face > g.n) return null;
            var face_seen = [_]bool{false} ** N;
            for (0..length_face) |i| {
                const a = cycle[i];
                const b = cycle[(i + 1) % length_face];
                if (face_seen[a] or g.dart_face[a][b] >= 0) return null;
                face_seen[a] = true;
            }
            const face_id: i32 = @intCast(g.f);
            g.face_len[g.f] = length_face;
            for (0..length_face) |i| {
                const a = cycle[i];
                const b = cycle[(i + 1) % length_face];
                g.face[g.f][i] = a;
                g.dart_face[a][b] = face_id;
            }
            g.f += 1;
        }
    }
    if (g.f != g.m - g.n + 2) return null;
    g.outer_id = F;
    for (0..g.f) |f| {
        if (g.face_len[f] == g.b and cyclicEqual(g.outer[0..g.b], g.face[f][0..g.b])) g.outer_id = f;
    }
    if (g.outer_id == F) return null;
    var fixed_count: usize = 0;
    for (0..g.n) |v| if (g.permutation[v] == v) { g.center = v; fixed_count += 1; };
    if (fixed_count != 1 or outer_seen[g.center]) return null;
    for (0..g.n) |v| {
        if (v == g.center) continue;
        var current = g.permutation[v];
        var orbit_length: usize = 1;
        while (current != v and orbit_length <= g.k) {
            current = g.permutation[current];
            orbit_length += 1;
        }
        if (current != v or orbit_length != g.k) return null;
    }
    var power = [_]usize{0} ** N;
    for (0..g.n) |v| power[v] = v;
    for (1..g.k + 1) |step| {
        var next = [_]usize{0} ** N;
        var identity = true;
        for (0..g.n) |v| {
            next[v] = g.permutation[power[v]];
            if (next[v] != v) identity = false;
        }
        if (identity != (step == g.k)) return null;
        power = next;
    }
    for (0..g.n) |u| {
        const image = g.permutation[u];
        for (0..g.n) |v| if (g.adjacent[u][v] != g.adjacent[image][g.permutation[v]]) return null;
        var row_ok = false;
        for (0..g.degree[image]) |shift| {
            var equal = true;
            for (0..g.degree[u]) |i| {
                if (g.permutation[g.rotation[u][i]] != g.rotation[image][(i + shift) % g.degree[image]]) equal = false;
            }
            if (equal) row_ok = true;
        }
        if (!row_ok) return null;
    }
    const shift = g.b / g.k;
    for (0..g.b) |i| if (g.permutation[g.outer[i]] != g.outer[(i + shift) % g.b]) return null;
    return g;
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output[offset + i] = @truncate(bits >> @intCast(8 * i));
}

fn solve(g: *const Graph, words: *[29]i64) i32 {
    var distance = [_]i32{-1} ** N;
    var queue = [_]usize{0} ** N;
    var head: usize = 0;
    var tail: usize = 1;
    distance[g.center] = 0;
    queue[0] = g.center;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..g.n) |v| if (g.adjacent[u][v] and distance[v] < 0) {
            distance[v] = distance[u] + 1;
            queue[tail] = v;
            tail += 1;
        };
    }
    var endpoint: ?usize = null;
    for (0..g.b) |i| {
        const v = g.outer[i];
        if (endpoint == null or distance[v] < distance[endpoint.?] or
            (distance[v] == distance[endpoint.?] and v < endpoint.?)) endpoint = v;
    }
    const v1 = endpoint orelse return -1;
    if (distance[v1] <= 0) return -1;
    var to_end = [_]i32{-1} ** N;
    head = 0; tail = 1; to_end[v1] = 0; queue[0] = v1;
    while (head < tail) {
        const u = queue[head]; head += 1;
        for (0..g.n) |v| if (g.adjacent[u][v] and to_end[v] < 0) {
            to_end[v] = to_end[u] + 1;
            queue[tail] = v;
            tail += 1;
        };
    }
    var p1 = [_]usize{0} ** N;
    var p2 = [_]usize{0} ** N;
    var p1_len: usize = 1;
    p1[0] = g.center;
    while (p1[p1_len - 1] != v1 and p1_len < N) {
        const u = p1[p1_len - 1];
        var choice: ?usize = null;
        for (0..g.n) |v| if (g.adjacent[u][v] and to_end[v] == to_end[u] - 1 and
            (choice == null or v < choice.?)) { choice = v; };
        p1[p1_len] = choice orelse return -1;
        p1_len += 1;
    }
    if (p1[p1_len - 1] != v1 or @as(i32, @intCast(p1_len - 1)) != distance[v1]) return -1;
    for (0..p1_len) |i| p2[i] = g.permutation[p1[i]];
    const v2 = p2[p1_len - 1];
    if (v1 == v2) return -1;
    for (1..p1_len) |i| for (1..p1_len) |j| if (p1[i] == p2[j]) return -1;
    for (1..p1_len - 1) |i| for (0..g.b) |j| if (p1[i] == g.outer[j]) return -1;
    for (1..p1_len - 1) |i| for (0..g.b) |j| if (p2[i] == g.outer[j]) return -1;
    var start: ?usize = null;
    for (0..g.b) |i| if (g.outer[i] == v1) { start = i; };
    const start_i = start orelse return -1;
    const p0_len = g.b / g.k + 1;
    var p0 = [_]usize{0} ** N;
    for (0..p0_len) |i| p0[i] = g.outer[(start_i + i) % g.b];
    if (p0[p0_len - 1] != v2) return -1;
    var cycle = [_]usize{0} ** (3 * N);
    var cycle_len: usize = 0;
    for (0..p1_len) |i| { cycle[cycle_len] = p1[i]; cycle_len += 1; }
    for (1..p0_len) |i| { cycle[cycle_len] = p0[i]; cycle_len += 1; }
    var i = p1_len - 1;
    while (i > 0) { i -= 1; cycle[cycle_len] = p2[i]; cycle_len += 1; }
    if (cycle[0] != g.center or cycle[cycle_len - 1] != g.center) return -1;
    var cycle_vertex = [_]bool{false} ** N;
    var cut = [_][N]bool{[_]bool{false} ** N} ** N;
    for (0..cycle_len - 1) |j| {
        const u = cycle[j];
        const v = cycle[j + 1];
        if (!g.adjacent[u][v] or cycle_vertex[u]) return -1;
        cycle_vertex[u] = true;
        cut[u][v] = true;
        cut[v][u] = true;
    }
    const seed_raw = g.dart_face[p0[1]][p0[0]];
    if (seed_raw < 0 or @as(usize, @intCast(seed_raw)) == g.outer_id) return -1;
    const seed: usize = @intCast(seed_raw);
    var dual = [_][F]bool{[_]bool{false} ** F} ** F;
    for (0..g.m) |e| {
        const u = g.edge_u[e];
        const v = g.edge_v[e];
        if (cut[u][v]) continue;
        const a: usize = @intCast(g.dart_face[u][v]);
        const b: usize = @intCast(g.dart_face[v][u]);
        dual[a][b] = true;
        dual[b][a] = true;
    }
    var inside = [_]bool{false} ** F;
    head = 0; tail = 1; queue[0] = seed; inside[seed] = true;
    while (head < tail) {
        const f = queue[head]; head += 1;
        for (0..g.f) |other| if (dual[f][other] and !inside[other]) {
            inside[other] = true;
            queue[tail] = other;
            tail += 1;
        };
    }
    if (inside[g.outer_id]) return -1;
    var vertices = cycle_vertex;
    for (0..g.f) |f| if (inside[f]) {
        for (0..g.face_len[f]) |j| vertices[g.face[f][j]] = true;
    };
    var vertex_mask: i64 = 0;
    var edge_mask: i64 = 0;
    for (0..g.n) |v| if (vertices[v]) { vertex_mask |= @as(i64, 1) << @intCast(v); };
    for (0..g.m) |e| if (vertices[g.edge_u[e]] and vertices[g.edge_v[e]]) {
        edge_mask |= @as(i64, 1) << @intCast(e);
    };
    var count: usize = 0;
    words[count] = @intCast(p1_len); count += 1;
    for (0..p1_len) |j| { words[count] = @intCast(p1[j]); count += 1; }
    words[count] = @intCast(p1_len); count += 1;
    for (0..p1_len) |j| { words[count] = @intCast(p2[j]); count += 1; }
    words[count] = @intCast(p0_len); count += 1;
    for (0..p0_len) |j| { words[count] = @intCast(p0[j]); count += 1; }
    words[count] = vertex_mask; words[count + 1] = edge_mask;
    return @intCast(count + 2);
}

export fn symmetric_drawing_cyclic_wedge(input: ?[*]const i64, input_length: usize,
    output_opt: ?[*]u8, output_capacity: usize) i64 {
    const input_words = input orelse return -1;
    if (input_length < 3 or input_length > INPUT_MAX) return -1;
    const graph = parse(input_words, input_length) orelse return -1;
    var words = [_]i64{0} ** 29;
    const count = solve(&graph, &words);
    if (count < 0 or @as(usize, @intCast(count)) * 8 > OUTPUT_MAX) return -1;
    const bytes: usize = @intCast(count * 8);
    const output = output_opt orelse return -2;
    if (output_capacity < bytes) return -2;
    var temporary = [_]u8{0} ** OUTPUT_MAX;
    for (0..@intCast(count)) |i| writeI64Le(&temporary, i * 8, words[i]);
    @memcpy(output[0..bytes], temporary[0..bytes]);
    return @intCast(bytes);
}
