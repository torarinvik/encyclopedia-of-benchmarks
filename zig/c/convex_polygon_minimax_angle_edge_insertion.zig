const MIN_N: usize = 3;
const MAX_N: usize = 4;
const MAX_LENGTH: usize = 10;
const MAX_ANGLES: usize = 12;

const Point = struct { x: i64, y: i64 };
const AngleRef = struct { a: usize, b: usize, c: usize, vertex: usize };
const Triangle = struct { a: usize, b: usize, c: usize };
const AngleParts = struct { dot: i64, den: i64 };

fn orient(p: [MAX_N]Point, a: usize, b: usize, c: usize) i64 {
    return (p[b].x - p[a].x) * (p[c].y - p[a].y) - (p[b].y - p[a].y) * (p[c].x - p[a].x);
}

fn angleParts(p: [MAX_N]Point, angle: AngleRef) AngleParts {
    const vertices = [_]usize{ angle.a, angle.b, angle.c };
    const center = vertices[angle.vertex];
    var endpoints: [2]usize = .{ 0, 0 };
    var used: usize = 0;
    for (vertices) |vertex| {
        if (vertex != center) { endpoints[used] = vertex; used += 1; }
    }
    const ux = p[endpoints[0]].x - p[center].x;
    const uy = p[endpoints[0]].y - p[center].y;
    const vx = p[endpoints[1]].x - p[center].x;
    const vy = p[endpoints[1]].y - p[center].y;
    return .{ .dot = ux * vx + uy * vy, .den = (ux * ux + uy * uy) * (vx * vx + vy * vy) };
}

fn angleCmp(p: [MAX_N]Point, left: AngleRef, right: AngleRef) i32 {
    const l = angleParts(p, left);
    const r = angleParts(p, right);
    if (l.dot == 0 or r.dot == 0) {
        if (l.dot == r.dot) return 0;
        if (l.dot == 0) return if (r.dot > 0) 1 else -1;
        return if (l.dot > 0) -1 else 1;
    }
    if ((l.dot < 0) != (r.dot < 0)) return if (l.dot < 0) 1 else -1;
    const lhs = l.dot * l.dot * r.den;
    const rhs = r.dot * r.dot * l.den;
    if (lhs == rhs) return 0;
    if (l.dot > 0) return if (lhs > rhs) -1 else 1;
    return if (lhs > rhs) 1 else -1;
}

fn triangleMax(p: [MAX_N]Point, t: Triangle) AngleRef {
    var v = [_]usize{ t.a, t.b, t.c };
    for (0..3) |i| for (i + 1..3) |j| {
        if (v[i] > v[j]) { const tmp = v[i]; v[i] = v[j]; v[j] = tmp; }
    };
    var best = AngleRef{ .a = v[0], .b = v[1], .c = v[2], .vertex = 0 };
    for (1..3) |vertex| {
        const candidate = AngleRef{ .a = v[0], .b = v[1], .c = v[2], .vertex = vertex };
        if (angleCmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

fn triangulationMax(p: [MAX_N]Point, triangles: []const Triangle) AngleRef {
    var best = triangleMax(p, triangles[0]);
    for (triangles[1..]) |triangle| {
        const candidate = triangleMax(p, triangle);
        if (angleCmp(p, candidate, best) > 0) best = candidate;
    }
    return best;
}

fn angleRank(p: [MAX_N]Point, n: usize, target: AngleRef) i64 {
    var distinct_lower: [MAX_ANGLES]AngleRef = undefined;
    var count: usize = 0;
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| for (0..3) |vertex| {
        const candidate = AngleRef{ .a = a, .b = b, .c = c, .vertex = vertex };
        if (angleCmp(p, candidate, target) >= 0) continue;
        var seen = false;
        for (distinct_lower[0..count]) |previous| {
            if (angleCmp(p, candidate, previous) == 0) { seen = true; break; }
        }
        if (!seen) { distinct_lower[count] = candidate; count += 1; }
    };
    return @intCast(count + 1);
}

fn properCrossing(p: [MAX_N]Point, a: usize, b: usize, c: usize, d: usize) bool {
    return orient(p, a, b, c) * orient(p, a, b, d) < 0 and orient(p, c, d, a) * orient(p, c, d, b) < 0;
}

export fn convex_polygon_minimax_angle_edge_insertion(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < @as(i64, @intCast(MIN_N)) or input[0] > @as(i64, @intCast(MAX_N))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    var points: [MAX_N]Point = @splat(.{ .x = 0, .y = 0 });
    for (0..n) |i| {
        points[i] = .{ .x = input[1 + 2 * i], .y = input[2 + 2 * i] };
        if (points[i].x < -16 or points[i].x > 16 or points[i].y < -16 or points[i].y > 16) return -1;
        for (0..i) |j| if (points[i].x == points[j].x and points[i].y == points[j].y) return -1;
    }
    var area2: i64 = 0;
    for (0..n) |i| {
        const next = (i + 1) % n;
        area2 += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if (area2 == 0) return -1;
    const orientation: i64 = if (area2 > 0) 1 else -1;
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        if (orient(points, a, b, c) == 0) return -1;
    };
    for (0..n) |edge| {
        const next = (edge + 1) % n;
        for (0..n) |vertex| {
            if (vertex != edge and vertex != next and orientation * orient(points, edge, next, vertex) <= 0) return -1;
        }
    }

    const fan = [_]Triangle{
        .{ .a = 0, .b = 1, .c = 2 },
        .{ .a = 0, .b = 2, .c = 3 },
    };
    var worst = if (n == 3) triangleMax(points, .{ .a = 0, .b = 1, .c = 2 }) else triangulationMax(points, &fan);
    if (n == 4) {
        var accepted = false;
        for (fan) |triangle| {
            if (accepted) break;
            const vertices = [_]usize{ triangle.a, triangle.b, triangle.c };
            for (0..3) |vertex| {
                if (accepted) break;
                const candidate = AngleRef{ .a = vertices[0], .b = vertices[1], .c = vertices[2], .vertex = vertex };
                if (angleCmp(points, candidate, worst) != 0) continue;
                const q = vertices[vertex];
                var opposite: [2]usize = .{ 0, 0 };
                var used: usize = 0;
                var s: usize = 4;
                for (0..3) |i| if (i != vertex) { opposite[used] = vertices[i]; used += 1; };
                for (0..4) |point| if (point != vertices[0] and point != vertices[1] and point != vertices[2]) { s = point; };
                if (!properCrossing(points, q, s, opposite[0], opposite[1])) continue;
                const inserted = [_]Triangle{
                    .{ .a = q, .b = s, .c = opposite[0] },
                    .{ .a = q, .b = s, .c = opposite[1] },
                };
                const replacement = triangulationMax(points, &inserted);
                if (angleCmp(points, replacement, worst) < 0) { worst = replacement; accepted = true; }
            }
        }
    }
    return angleRank(points, n, worst);
}
