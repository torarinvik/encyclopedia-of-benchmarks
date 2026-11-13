const MIN_VERTICES: usize = 3;
const MAX_VERTICES: usize = 12;
const MAX_PARSEABLE_LENGTH: usize = 26;
const COORD_LIMIT: i64 = 1000;

const Point = struct { x: i64, y: i64 };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn squared_length(points: []const Point, left: usize, right: usize) i64 {
    const dx = points[left].x - points[right].x;
    const dy = points[left].y - points[right].y;
    return dx * dx + dy * dy;
}

export fn convex_polygon_minimax_length_triangulation(input_opt: ?[*]const i64, length: usize) i64 {
    if (input_opt == null or length < 1 or length > MAX_PARSEABLE_LENGTH) return -1;
    const input = input_opt.?;
    if (input[0] < @as(i64, @intCast(MIN_VERTICES)) or
        input[0] > @as(i64, @intCast(MAX_VERTICES))) return -1;
    const n: usize = @intCast(input[0]);
    if (length != 1 + 2 * n) return -1;
    var points: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    for (0..n) |i| {
        points[i] = .{ .x = input[1 + 2 * i], .y = input[2 + 2 * i] };
        if (points[i].x < -COORD_LIMIT or points[i].x > COORD_LIMIT or
            points[i].y < -COORD_LIMIT or points[i].y > COORD_LIMIT) return -1;
    }
    var area2: i64 = 0;
    for (0..n) |i| {
        const next = (i + 1) % n;
        area2 += points[i].x * points[next].y - points[i].y * points[next].x;
    }
    if (area2 == 0) return -1;
    const orientation: i64 = if (area2 > 0) 1 else -1;
    for (0..n) |edge| {
        const next = (edge + 1) % n;
        for (0..n) |vertex| {
            if (vertex != edge and vertex != next and orientation * cross(points[edge], points[next], points[vertex]) <= 0) return -1;
        }
    }

    var best = [_]i64{0} ** (MAX_VERTICES * MAX_VERTICES);
    for (0..n - 1) |left| best[left * MAX_VERTICES + left + 1] = squared_length(points[0..n], left, left + 1);
    for (2..n) |span| {
        for (0..n - span) |left| {
            const right = left + span;
            const boundary = squared_length(points[0..n], left, right);
            var optimum: i64 = 8_000_001;
            for (left + 1..right) |middle| {
                var candidate = @max(best[left * MAX_VERTICES + middle], best[middle * MAX_VERTICES + right]);
                candidate = @max(candidate, boundary);
                optimum = @min(optimum, candidate);
            }
            best[left * MAX_VERTICES + right] = optimum;
        }
    }
    return best[n - 1];
}
