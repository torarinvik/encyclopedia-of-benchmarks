const N: usize = 6;
const M: usize = 10;
const D: usize = 20;
const F: usize = 10;
const MAX_INPUT: usize = 61;
const MAX_AUG: usize = 25;
const INF: i64 = std.math.maxInt(i64) / 4;
const std = @import("std");

const Graph = struct {
    n: usize = 0, m: usize = 0, source: usize = 0, sink: usize = 0,
    tail: [M]usize = [_]usize{0} ** M,
    head: [M]usize = [_]usize{0} ** M,
    cap: [M]i32 = [_]i32{0} ** M,
    degree: [N]usize = [_]usize{0} ** N,
    rotation: [N][N]usize = [_][N]usize{[_]usize{0} ** N} ** N,
    pos: [N][M]i32 = [_][M]i32{[_]i32{-1} ** M} ** N,
    left_face: [D]usize = [_]usize{0} ** D,
    right_face: [D]usize = [_]usize{0} ** D,
    faces: usize = 0, infinity: usize = 0, root_anchor: usize = 0,
};

fn dartHead(g: *const Graph, dart: usize) usize {
    const e = dart / 2;
    return if (dart % 2 == 0) g.head[e] else g.tail[e];
}

fn leftSuccessor(g: *const Graph, dart: usize) ?usize {
    const vertex = dartHead(g, dart);
    const edge = dart / 2;
    const degree = g.degree[vertex];
    const position = g.pos[vertex][edge];
    if (degree == 0 or position < 0) return null;
    const prior = g.rotation[vertex][(@as(usize, @intCast(position)) + degree - 1) % degree];
    return 2 * prior + @as(usize, @intFromBool(g.head[prior] == vertex));
}

fn parse(a: []const i64) ?Graph {
    if (a.len < 4 or a.len > MAX_INPUT) return null;
    const n0 = a[0]; const m0 = a[1]; const s0 = a[2]; const t0 = a[3];
    if (n0 < 2 or n0 > 6 or m0 < 1 or m0 > 10 or s0 < 0 or s0 >= n0 or t0 < 0 or t0 >= n0 or s0 == t0) return null;
    var g = Graph{};
    g.n = @intCast(n0); g.m = @intCast(m0); g.source = @intCast(s0); g.sink = @intCast(t0);
    if (a.len < 4 + 3 * g.m) return null;
    var pairs = [_][N]bool{[_]bool{false} ** N} ** N;
    var at: usize = 4;
    for (0..g.m) |e| {
        const u0 = a[at]; const v0 = a[at + 1]; const c0 = a[at + 2]; at += 3;
        if (u0 < 0 or u0 >= n0 or v0 < 0 or v0 >= n0 or u0 == v0 or c0 < 1 or c0 > 5) return null;
        const u: usize = @intCast(u0); const v: usize = @intCast(v0);
        if (pairs[u][v] or pairs[v][u]) return null;
        pairs[u][v] = true; pairs[v][u] = true;
        g.tail[e] = u; g.head[e] = v; g.cap[e] = @intCast(c0);
    }
    var occurrences = [_][2]usize{[_]usize{0} ** 2} ** M;
    var used = [_][M]bool{[_]bool{false} ** M} ** N;
    for (0..g.n) |x| {
        if (at >= a.len) return null;
        const d0 = a[at]; at += 1;
        if (d0 < 1 or d0 >= n0 or at + @as(usize, @intCast(d0)) > a.len) return null;
        g.degree[x] = @intCast(d0);
        for (0..g.degree[x]) |j| {
            const e0 = a[at]; at += 1;
            if (e0 < 0 or e0 >= m0) return null;
            const e: usize = @intCast(e0);
            if (used[x][e]) return null;
            used[x][e] = true; g.rotation[x][j] = e; g.pos[x][e] = @intCast(j);
            if (g.tail[e] == x) occurrences[e][0] += 1 else if (g.head[e] == x) occurrences[e][1] += 1 else return null;
        }
    }
    if (at != a.len) return null;
    for (0..g.m) |e| if (occurrences[e][0] != 1 or occurrences[e][1] != 1) return null;

    var adjacent = [_][N]bool{[_]bool{false} ** N} ** N;
    for (0..g.m) |e| { adjacent[g.tail[e]][g.head[e]] = true; adjacent[g.head[e]][g.tail[e]] = true; }
    var seen = [_]bool{false} ** N; var queue = [_]usize{0} ** N;
    var qh: usize = 0; var qt: usize = 1; seen[g.source] = true; queue[0] = g.source;
    while (qh < qt) {
        const x = queue[qh]; qh += 1;
        for (0..g.n) |y| if (adjacent[x][y] and !seen[y]) { seen[y] = true; queue[qt] = y; qt += 1; };
    }
    for (0..g.n) |x| if (!seen[x]) return null;

    var face_of = [_]i32{-1} ** D;
    for (0..2 * g.m) |start| {
        if (face_of[start] >= 0) continue;
        var dart = start;
        while (face_of[dart] < 0) {
            face_of[dart] = @intCast(g.faces);
            dart = leftSuccessor(&g, dart) orelse return null;
        }
        if (dart != start) return null;
        g.faces += 1;
    }
    if (g.faces != g.m - g.n + 2) return null;
    for (0..2 * g.m) |dart| {
        g.left_face[dart] = @intCast(face_of[dart]);
        g.right_face[dart] = @intCast(face_of[dart ^ 1]);
    }
    g.root_anchor = g.rotation[g.sink][0];
    const root_dart = 2 * g.root_anchor + @as(usize, @intFromBool(g.head[g.root_anchor] == g.sink));
    g.infinity = g.right_face[root_dart];
    return g;
}

fn visit(g: *const Graph, vertex: usize, anchor: usize, root: bool,
    residual: *const [N][N]i32, seen: *[N]bool, parent: *[N]i32) void {
    const degree = g.degree[vertex];
    const pos: usize = @intCast(g.pos[vertex][anchor]);
    const first: usize = if (root) 0 else 1;
    for (first..first + degree) |step| {
        const edge = g.rotation[vertex][(pos + step) % degree];
        const neighbor = if (g.tail[edge] == vertex) g.head[edge] else g.tail[edge];
        if (!seen[neighbor] and residual.*[neighbor][vertex] > 0) {
            seen[neighbor] = true; parent[neighbor] = @intCast(vertex);
            visit(g, neighbor, edge, false, residual, seen, parent);
        }
    }
}

fn solve(g: *const Graph) ?i64 {
    var dual = [_][F]i64{[_]i64{INF} ** F} ** F;
    for (0..2 * g.m) |dart| {
        const from = g.right_face[dart]; const to = g.left_face[dart];
        const weight: i64 = if (dart % 2 == 0) g.cap[dart / 2] else 0;
        dual[from][to] = @min(dual[from][to], weight);
    }
    var distance = [_]i64{INF} ** F; var settled = [_]bool{false} ** F;
    distance[g.infinity] = 0;
    for (0..g.faces) |_| {
        var current: ?usize = null;
        for (0..g.faces) |f| if (!settled[f] and (current == null or distance[f] < distance[current.?])) { current = f; };
        const c = current orelse break;
        if (distance[c] == INF) break;
        settled[c] = true;
        for (0..g.faces) |next| if (dual[c][next] != INF) { distance[next] = @min(distance[next], distance[c] + dual[c][next]); };
    }
    var residual = [_][N]i32{[_]i32{0} ** N} ** N;
    for (0..g.m) |e| {
        const eta = distance[g.left_face[2 * e]] - distance[g.right_face[2 * e]];
        if (eta < 0 or eta > g.cap[e]) return null;
        residual[g.tail[e]][g.head[e]] += g.cap[e] - @as(i32, @intCast(eta));
        residual[g.head[e]][g.tail[e]] += @intCast(eta);
    }
    var value: i64 = 0;
    for (0..MAX_AUG + 1) |augmentation| {
        var seen = [_]bool{false} ** N; var parent = [_]i32{-1} ** N; seen[g.sink] = true;
        visit(g, g.sink, g.root_anchor, true, &residual, &seen, &parent);
        if (!seen[g.source]) return value;
        if (augmentation == MAX_AUG) return null;
        var delta: i32 = std.math.maxInt(i32); var x = g.source;
        while (x != g.sink) { const y: usize = @intCast(parent[x]); delta = @min(delta, residual[x][y]); x = y; }
        x = g.source;
        while (x != g.sink) { const y: usize = @intCast(parent[x]); residual[x][y] -= delta; residual[y][x] += delta; x = y; }
        value += delta;
    }
    return null;
}

export fn planar_directed_general_st_flow_borradaile_klein(input_ptr: ?[*]const i64, length: usize, output_ptr: ?[*]u8, capacity: usize) i64 {
    if (input_ptr == null or length > MAX_INPUT) return -1;
    const input = input_ptr.?[0..length];
    const graph = parse(input) orelse return -1;
    const value = solve(&graph) orelse return -1;
    if (output_ptr == null or capacity < 8) return -2;
    const bits: u64 = @bitCast(value);
    for (0..8) |i| output_ptr.?[i] = @truncate(bits >> @as(u6, @intCast(8 * i)));
    return 8;
}
