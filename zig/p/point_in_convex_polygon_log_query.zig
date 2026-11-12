const MAX_VERTICES: usize = 32;
const MAX_QUERIES: usize = 32;
const MAX_INPUT: usize = 131;
const MAX_COORD: i64 = 1_000_000;

const Point = struct { x: i64, y: i64 };
fn sub(a: Point, b: Point) Point { return .{ .x = a.x - b.x, .y = a.y - b.y }; }
fn cross(a: Point, b: Point) i64 { return a.x * b.y - a.y * b.x; }
fn on_segment(a: Point, b: Point, p: Point) bool {
    const e = sub(b, a); const r = sub(p, a);
    return cross(e, r) == 0 and p.x >= @min(a.x, b.x) and p.x <= @max(a.x, b.x)
        and p.y >= @min(a.y, b.y) and p.y <= @max(a.y, b.y);
}
fn valid_polygon(p: []const Point) bool {
    for (0..p.len) |i| {
        const next = (i + 1) % p.len;
        if (p[i].x == p[next].x and p[i].y == p[next].y) return false;
        const edge = sub(p[next], p[i]);
        for (0..p.len) |j| {
            if (j != i and j != next and cross(edge, sub(p[j], p[i])) <= 0) return false;
        }
        for (i + 1..p.len) |j| {
            if (p[i].x == p[j].x and p[i].y == p[j].y) return false;
        }
    }
    return true;
}
fn contains_fan(fan: []const Point, query: Point) i64 {
    const origin = Point{ .x = 0, .y = 0 };
    const first = cross(fan[0], query); const last = cross(fan[fan.len - 1], query);
    if (first < 0 or last > 0) return 0;
    if (first == 0) return if (on_segment(origin, fan[0], query)) 1 else 0;
    if (last == 0) return if (on_segment(origin, fan[fan.len - 1], query)) 1 else 0;
    var lo: usize = 0; var hi: usize = fan.len;
    while (hi - lo > 1) {
        const mid = (lo + hi) / 2;
        if (cross(fan[mid], query) >= 0) lo = mid else hi = mid;
    }
    const side = cross(sub(fan[lo + 1], fan[lo]), sub(query, fan[lo]));
    if (side < 0) return 0;
    if (side == 0) return if (on_segment(fan[lo], fan[lo + 1], query)) 1 else 0;
    return 1;
}
fn put_i64(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @as(u6, @intCast(8 * b))); offset.* += 1; }
}

export fn point_in_convex_polygon_log_query(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 2 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > 32 or input[1] < 0 or input[1] > 32) return -1;
    const vertices: usize = @intCast(input[0]); const queries: usize = @intCast(input[1]);
    if (length != 2 + 2 * vertices + 2 * queries) return -1;
    var polygon: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var fan: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var query_points: [MAX_QUERIES]Point = @splat(.{ .x = 0, .y = 0 });
    var answers: [MAX_QUERIES]i64 = @splat(0);
    var at: usize = 2;
    for (0..vertices) |i| {
        polygon[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (polygon[i].x < -MAX_COORD or polygon[i].x > MAX_COORD or polygon[i].y < -MAX_COORD or polygon[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(polygon[0..vertices])) return -1;
    for (0..queries) |i| {
        query_points[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (query_points[i].x < -MAX_COORD or query_points[i].x > MAX_COORD or query_points[i].y < -MAX_COORD or query_points[i].y > MAX_COORD) return -1;
    }
    var pivot: usize = 0;
    for (1..vertices) |i| {
        if (polygon[i].x < polygon[pivot].x or (polygon[i].x == polygon[pivot].x and polygon[i].y < polygon[pivot].y)) pivot = i;
    }
    for (0..vertices - 1) |i| fan[i] = sub(polygon[(pivot + i + 1) % vertices], polygon[pivot]);
    for (0..queries) |i| answers[i] = contains_fan(fan[0 .. vertices - 1], sub(query_points[i], polygon[pivot]));
    const needed = 8 * queries;
    if (needed > capacity or (needed != 0 and output_opt == null)) return -2;
    if (needed == 0) return 0;
    const output = output_opt.?;
    var offset: usize = 0;
    for (0..queries) |i| put_i64(output, &offset, answers[i]);
    return @intCast(needed);
}
