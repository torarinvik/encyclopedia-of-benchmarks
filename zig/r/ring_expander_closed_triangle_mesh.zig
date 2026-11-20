const max_n: usize = 12;
const max_t: usize = 20;
const max_c: usize = 60;
const max_input: usize = 64;

fn nextCorner(corner: usize) usize { return 3 * (corner / 3) + (corner % 3 + 1) % 3; }
fn prevCorner(corner: usize) usize { return 3 * (corner / 3) + (corner % 3 + 2) % 3; }
fn cornerVertex(faces: *const [max_c]i64, corner: usize) usize {
    return @intCast(faces[3 * (corner / 3) + corner % 3]);
}

fn putWord(output: [*]u8, at: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[at + byte] = @truncate(bits >> @intCast(8 * byte));
}

fn runRing(n: usize, t: usize, seed: usize, faces: *const [max_c]i64,
    trace: *[max_c]i64, trace_count: *usize, vertex_mask: *u64, triangle_mask: *u64) bool {
    var opposite: [max_c]i32 = @splat(-1);
    var link: [max_n][max_n][max_n]bool = undefined;
    for (0..max_n) |a| {
        for (0..max_n) |b| {
            for (0..max_n) |c| link[a][b][c] = false;
        }
    }
    var used: [max_n]bool = @splat(false);
    var edge_count: [max_n][max_n]u8 = @splat(@splat(0));
    var edge_first: [max_n][max_n]i32 = @splat(@splat(-1));
    var edge_second: [max_n][max_n]i32 = @splat(@splat(-1));
    for (0..t) |ti| {
        const a: usize = @intCast(faces[3 * ti]);
        const b: usize = @intCast(faces[3 * ti + 1]);
        const c: usize = @intCast(faces[3 * ti + 2]);
        used[a] = true; used[b] = true; used[c] = true;
        link[a][b][c] = true; link[a][c][b] = true;
        link[b][c][a] = true; link[b][a][c] = true;
        link[c][a][b] = true; link[c][b][a] = true;
        for (0..3) |j| {
            const first: usize = @intCast(faces[3 * ti + (j + 1) % 3]);
            const second: usize = @intCast(faces[3 * ti + (j + 2) % 3]);
            const low = @min(first, second);
            const high = @max(first, second);
            const count = edge_count[low][high];
            if (count == 0) edge_first[low][high] = @intCast(3 * ti + j)
            else if (count == 1) edge_second[low][high] = @intCast(3 * ti + j)
            else return false;
            edge_count[low][high] = count + 1;
        }
    }
    for (0..n) |v| if (!used[v]) return false;

    for (0..n) |low| {
        for (low + 1..n) |high| {
            const count = edge_count[low][high];
            if (count == 0) continue;
            if (count != 2) return false;
            const a: usize = @intCast(edge_first[low][high]);
            const b: usize = @intCast(edge_second[low][high]);
            const at = a / 3; const aj = a % 3;
            const bt = b / 3; const bj = b % 3;
            const a0 = faces[3 * at + (aj + 1) % 3];
            const a1 = faces[3 * at + (aj + 2) % 3];
            const b0 = faces[3 * bt + (bj + 1) % 3];
            const b1 = faces[3 * bt + (bj + 2) % 3];
            if (a0 != b1 or a1 != b0) return false;
            opposite[a] = @intCast(b);
            opposite[b] = @intCast(a);
        }
    }

    for (0..n) |v| {
        var start: ?usize = null;
        for (0..n) |w| {
            var degree: usize = 0;
            for (0..n) |x| {
                if (link[v][w][x]) degree += 1;
            }
            if (degree > 0 and start == null) start = w;
            if (degree > 0 and degree != 2) return false;
        }
        const first = start orelse return false;
        var seen: [max_n]bool = @splat(false);
        var queue: [max_n]usize = @splat(0);
        var head: usize = 0; var tail: usize = 0;
        seen[first] = true; queue[tail] = first; tail += 1;
        while (head < tail) {
            const w = queue[head]; head += 1;
            for (0..n) |x| {
                if (link[v][w][x] and !seen[x]) { seen[x] = true; queue[tail] = x; tail += 1; }
            }
        }
        for (0..n) |w| {
            var has_edge = false;
            for (0..n) |x| has_edge = has_edge or link[v][w][x];
            if (has_edge and !seen[w]) return false;
        }
    }

    var reached: [max_t]bool = @splat(false);
    var queue: [max_t]usize = @splat(0);
    var head: usize = 0; var tail: usize = 0;
    reached[0] = true; queue[tail] = 0; tail += 1;
    while (head < tail) {
        const ti = queue[head]; head += 1;
        for (0..3) |j| {
            const other: usize = @intCast(opposite[3 * ti + j]);
            const ot = other / 3;
            if (!reached[ot]) { reached[ot] = true; queue[tail] = ot; tail += 1; }
        }
    }
    for (0..t) |ti| if (!reached[ti]) return false;

    var seen_corners: [max_c]bool = @splat(false);
    trace_count.* = 0; vertex_mask.* = 0; triangle_mask.* = 0;
    vertex_mask.* |= @as(u64, 1) << @intCast(cornerVertex(faces, nextCorner(seed)));
    vertex_mask.* |= @as(u64, 1) << @intCast(cornerVertex(faces, prevCorner(seed)));
    const stop: usize = @intCast(opposite[seed]);
    var current = seed;
    while (current != stop) {
        if (current >= 3 * t or seen_corners[current] or trace_count.* >= 3 * t) return false;
        seen_corners[current] = true;
        trace[trace_count.*] = @intCast(current);
        trace_count.* += 1;
        const ti = current / 3;
        const v = cornerVertex(faces, current);
        if (((vertex_mask.* >> @intCast(v)) & 1) == 0) {
            vertex_mask.* |= @as(u64, 1) << @intCast(v);
            triangle_mask.* |= @as(u64, 1) << @intCast(ti);
        } else if (((triangle_mask.* >> @intCast(ti)) & 1) == 0) {
            current = @intCast(opposite[current]);
        }
        current = @intCast(opposite[prevCorner(current)]);
    }
    return true;
}

export fn ring_expander_closed_triangle_mesh(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 15 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0]; const t64 = input[1]; const seed64 = input[2];
    if (n64 < 4 or n64 > 12 or t64 < 4 or t64 > 20) return -1;
    const n: usize = @intCast(n64); const t: usize = @intCast(t64);
    if (length != 3 + 3 * t or seed64 < 0 or seed64 >= @as(i64, @intCast(3 * t))) return -1;
    const seed: usize = @intCast(seed64);
    var faces: [max_c]i64 = @splat(0);
    for (0..3 * t) |i| {
        const value = input[3 + i];
        if (value < 0 or value >= n64) return -1;
        faces[i] = value;
    }
    for (0..t) |ti| {
        const a = faces[3 * ti]; const b = faces[3 * ti + 1]; const c = faces[3 * ti + 2];
        if (a == b or b == c or c == a) return -1;
    }
    var trace: [max_c]i64 = @splat(0);
    var trace_count: usize = 0; var vertices: u64 = 0; var triangles: u64 = 0;
    if (!runRing(n, t, seed, &faces, &trace, &trace_count, &vertices, &triangles)) return -1;
    const bytes = 8 * (1 + trace_count + 2);
    if (output_opt == null or capacity < bytes) return -2;
    const output = output_opt.?;
    putWord(output, 0, @intCast(trace_count));
    for (0..trace_count) |i| putWord(output, 8 * (i + 1), trace[i]);
    putWord(output, 8 * (trace_count + 1), @intCast(vertices));
    putWord(output, 8 * (trace_count + 2), @intCast(triangles));
    return @intCast(bytes);
}
