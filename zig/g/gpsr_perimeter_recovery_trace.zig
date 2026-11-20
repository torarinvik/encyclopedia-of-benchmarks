const max_n: usize = 8;
const max_m: usize = 18;
const max_path: usize = 37;
const max_input: usize = 57;
const max_output: usize = 896;
const max_output_words: usize = 112;

const Point = struct { x: i64, y: i64 };
const Edge = struct { u: usize, v: usize };

fn cross(ax: i64, ay: i64, bx: i64, by: i64) i64 {
    return ax * by - ay * bx;
}

fn orient(points: *const [max_n]Point, a: usize, b: usize, c: usize) i64 {
    return cross(points[b].x - points[a].x, points[b].y - points[a].y,
        points[c].x - points[a].x, points[c].y - points[a].y);
}

fn halfPlane(x: i64, y: i64) usize {
    return if (y > 0 or (y == 0 and x >= 0)) 0 else 1;
}

fn angleLess(ax: i64, ay: i64, ai: usize, bx: i64, by: i64, bi: usize) bool {
    const ah = halfPlane(ax, ay);
    const bh = halfPlane(bx, by);
    if (ah != bh) return ah < bh;
    const turn = cross(ax, ay, bx, by);
    if (turn != 0) return turn > 0;
    return ai < bi;
}

fn segmentsCross(points: *const [max_n]Point, a: usize, b: usize, c: usize, d: usize) bool {
    return orient(points, a, b, c) * orient(points, a, b, d) < 0 and
        orient(points, c, d, a) * orient(points, c, d, b) < 0;
}

fn gcd64(a0: i64, b0: i64) i64 {
    var a = a0;
    var b = b0;
    while (b != 0) {
        const remainder = @rem(a, b);
        a = b;
        b = remainder;
    }
    return a;
}

fn properCrossing(p: Point, q: Point, a: Point, b: Point,
    numerator: *i64, denominator: *i64) bool {
    const rx = q.x - p.x;
    const ry = q.y - p.y;
    const sx = b.x - a.x;
    const sy = b.y - a.y;
    var den = cross(rx, ry, sx, sy);
    if (den == 0) return false;
    const ox = a.x - p.x;
    const oy = a.y - p.y;
    var tn = cross(ox, oy, sx, sy);
    var un = cross(ox, oy, rx, ry);
    if (den < 0) {
        den = -den;
        tn = -tn;
        un = -un;
    }
    if (!(tn > 0 and tn < den and un > 0 and un < den)) return false;
    const divisor = gcd64(tn, den);
    numerator.* = @divTrunc(tn, divisor);
    denominator.* = @divTrunc(den, divisor);
    return true;
}

fn edgeId(u0: usize, v0: usize, m: usize, edges: *const [max_m]Edge) ?usize {
    const lo = @min(u0, v0);
    const hi = @max(u0, v0);
    for (0..m) |i| {
        if (edges[i].u == lo and edges[i].v == hi) return i;
    }
    return null;
}

fn nextCcw(node: usize, incoming: usize, degree: *const [max_n]usize,
    rotation: *const [max_n][max_n]usize) ?usize {
    for (0..degree[node]) |i| {
        if (rotation[node][i] == incoming) return rotation[node][(i + 1) % degree[node]];
    }
    return null;
}

fn firstCcw(node: usize, target: usize, points: *const [max_n]Point,
    degree: *const [max_n]usize, adjacency: *const [max_n][max_n]usize) ?usize {
    const rx = points[target].x - points[node].x;
    const ry = points[target].y - points[node].y;
    var best: ?usize = null;
    var best_x: i64 = 0;
    var best_y: i64 = 0;
    for (0..degree[node]) |i| {
        const v = adjacency[node][i];
        const dx = points[v].x - points[node].x;
        const dy = points[v].y - points[node].y;
        const vx = rx * dx + ry * dy;
        const vy = cross(rx, ry, dx, dy);
        if (best == null or angleLess(vx, vy, v, best_x, best_y, best.?)) {
            best = v;
            best_x = vx;
            best_y = vy;
        }
    }
    return best;
}

fn put64(output: [*]u8, position: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[position + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn gpsr_perimeter_recovery_trace(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 4 or length > max_input) return -1;
    const input = input_opt.?;
    const n64 = input[0];
    const m64 = input[1];
    const source64 = input[2];
    const target64 = input[3];
    if (n64 < 3 or n64 > 8 or m64 < n64 - 1 or m64 > 18 or m64 > 3 * n64 - 6 or
        source64 < 0 or target64 < 0 or source64 >= n64 or target64 >= n64 or source64 == target64) return -1;
    const n: usize = @intCast(n64);
    const m: usize = @intCast(m64);
    const source: usize = @intCast(source64);
    const target: usize = @intCast(target64);
    if (length != 4 + 2 * n + 2 * m) return -1;

    var points: [max_n]Point = @splat(.{ .x = 0, .y = 0 });
    for (0..n) |i| {
        points[i] = .{ .x = input[4 + i], .y = input[4 + n + i] };
        if (points[i].x < -16 or points[i].x > 16 or points[i].y < -16 or points[i].y > 16) return -1;
        for (0..i) |j| {
            if (points[i].x == points[j].x and points[i].y == points[j].y) return -1;
        }
    }
    for (0..n) |i| {
        for (i + 1..n) |j| {
            for (j + 1..n) |k| {
                if (orient(&points, i, j, k) == 0) return -1;
            }
        }
    }

    var edges: [max_m]Edge = undefined;
    var adjacency: [max_n][max_n]usize = @splat(@splat(0));
    var degree: [max_n]usize = @splat(0);
    const edge_start = 4 + 2 * n;
    for (0..m) |i| {
        const u64 = input[edge_start + 2 * i];
        const v64 = input[edge_start + 2 * i + 1];
        if (u64 < 0 or v64 >= n64 or u64 >= v64) return -1;
        const u: usize = @intCast(u64);
        const v: usize = @intCast(v64);
        if (i > 0 and (edges[i - 1].u > u or (edges[i - 1].u == u and edges[i - 1].v >= v))) return -1;
        edges[i] = .{ .u = u, .v = v };
        adjacency[u][degree[u]] = v;
        adjacency[v][degree[v]] = u;
        degree[u] += 1;
        degree[v] += 1;
    }

    var reached: [max_n]bool = @splat(false);
    var queue: [max_n]usize = @splat(0);
    var head: usize = 0;
    var tail: usize = 1;
    reached[source] = true;
    queue[0] = source;
    while (head < tail) {
        const u = queue[head];
        head += 1;
        for (0..degree[u]) |i| {
            const v = adjacency[u][i];
            if (!reached[v]) {
                reached[v] = true;
                queue[tail] = v;
                tail += 1;
            }
        }
    }
    for (0..n) |i| if (!reached[i]) return -1;

    for (0..m) |i| {
        for (i + 1..m) |j| {
            const a = edges[i].u;
            const b = edges[i].v;
            const c = edges[j].u;
            const d = edges[j].v;
            if (a != c and a != d and b != c and b != d and segmentsCross(&points, a, b, c, d)) return -1;
        }
    }

    const sx = points[source].x - points[target].x;
    const sy = points[source].y - points[target].y;
    const source_distance = sx * sx + sy * sy;
    for (0..degree[source]) |i| {
        const v = adjacency[source][i];
        const dx = points[v].x - points[target].x;
        const dy = points[v].y - points[target].y;
        if (dx * dx + dy * dy < source_distance) return -1;
    }
    if (output_opt == null or capacity < max_output) return -2;
    const output = output_opt.?;

    var rotation: [max_n][max_n]usize = @splat(@splat(0));
    for (0..n) |u| {
        for (0..degree[u]) |i| rotation[u][i] = adjacency[u][i];
        for (1..degree[u]) |i| {
            const v = rotation[u][i];
            const dx = points[v].x - points[u].x;
            const dy = points[v].y - points[u].y;
            var j = i;
            while (j > 0) {
                const w = rotation[u][j - 1];
                if (!angleLess(dx, dy, v, points[w].x - points[u].x, points[w].y - points[u].y, w)) break;
                rotation[u][j] = w;
                j -= 1;
            }
            rotation[u][j] = v;
        }
    }

    var path: [max_path]usize = @splat(0);
    var events: [max_m][4]i64 = @splat(@splat(0));
    var path_count: usize = 1;
    var crossing_count: usize = 0;
    var current = source;
    var previous: ?usize = null;
    var e0: ?[2]usize = null;
    var lf_num: i64 = 0;
    var lf_den: i64 = 1;
    var status: i64 = 0;
    path[0] = source;
    while (true) {
        const dx = points[current].x - points[target].x;
        const dy = points[current].y - points[target].y;
        if (current == target) {
            status = 2;
            break;
        }
        if (dx * dx + dy * dy < source_distance) {
            status = 1;
            break;
        }
        if (path_count - 1 >= 2 * m) {
            status = 0;
            break;
        }
        var candidate_opt = if (previous == null)
            firstCcw(current, target, &points, &degree, &adjacency)
        else
            nextCcw(current, previous.?, &degree, &rotation);
        if (candidate_opt == null) {
            status = 0;
            break;
        }
        var candidate = candidate_opt.?;
        var changed_face = false;
        var invalid_state = false;
        while (true) {
            var t_num: i64 = 0;
            var t_den: i64 = 1;
            if (!properCrossing(points[source], points[target], points[current], points[candidate], &t_num, &t_den) or
                t_num * lf_den <= lf_num * t_den) break;
            const id = edgeId(current, candidate, m, &edges);
            if (id == null or crossing_count >= max_m) {
                status = 0;
                invalid_state = true;
                break;
            }
            const event_at = crossing_count;
            events[event_at] = .{ @intCast(path_count - 1), @intCast(id.?), t_num, t_den };
            crossing_count += 1;
            lf_num = t_num;
            lf_den = t_den;
            changed_face = true;
            candidate_opt = nextCcw(current, candidate, &degree, &rotation);
            if (candidate_opt == null) {
                status = 0;
                invalid_state = true;
                break;
            }
            candidate = candidate_opt.?;
        }
        if (invalid_state) break;
        if (changed_face or e0 == null) {
            e0 = .{ current, candidate };
        } else {
            const first = e0.?;
            if (first[0] == current and first[1] == candidate) {
                status = 0;
                break;
            }
        }
        previous = current;
        current = candidate;
        if (path_count >= max_path) {
            status = 0;
            break;
        }
        path[path_count] = current;
        path_count += 1;
    }

    var words: [max_output_words]i64 = @splat(0);
    var word_count: usize = 0;
    words[word_count] = status;
    word_count += 1;
    words[word_count] = @intCast(path_count - 1);
    word_count += 1;
    for (0..path_count) |i| {
        words[word_count] = @intCast(path[i]);
        word_count += 1;
    }
    words[word_count] = @intCast(crossing_count);
    word_count += 1;
    for (0..crossing_count) |i| {
        for (0..4) |j| {
            words[word_count] = events[i][j];
            word_count += 1;
        }
    }
    for (0..word_count) |i| put64(output, 8 * i, words[i]);
    return @intCast(8 * word_count);
}
