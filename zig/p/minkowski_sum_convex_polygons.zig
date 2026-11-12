const MAX_VERTICES: usize = 32;
const MAX_INPUT: usize = 131;
const MAX_COORD: i64 = 1000000;

const Point = struct { x: i64, y: i64 };

fn cross(a: Point, b: Point) i64 { return a.x * b.y - a.y * b.x; }
fn edge(p: []const Point, i: usize) Point {
    const next = p[(i + 1) % p.len];
    return .{ .x = next.x - p[i].x, .y = next.y - p[i].y };
}
fn half(v: Point) u8 { return if (v.y > 0 or (v.y == 0 and v.x >= 0)) 0 else 1; }
fn angle_compare(a: Point, b: Point) i8 {
    const ha = half(a); const hb = half(b);
    if (ha != hb) return if (ha < hb) -1 else 1;
    const turn = cross(a, b);
    return if (turn > 0) -1 else if (turn < 0) 1 else 0;
}
fn valid_polygon(p: []const Point) bool {
    var wraps: usize = 0;
    for (0..p.len) |i| {
        const a = edge(p, i); const b = edge(p, (i + 1) % p.len);
        if ((a.x == 0 and a.y == 0) or cross(a, b) <= 0) return false;
        if (angle_compare(b, a) < 0) wraps += 1;
    }
    return wraps == 1;
}
fn rotate_lowest(p: []Point) void {
    var first: usize = 0;
    for (1..p.len) |i| {
        if (p[i].y < p[first].y or (p[i].y == p[first].y and p[i].x < p[first].x)) first = i;
    }
    var tmp: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    for (0..p.len) |i| tmp[i] = p[(first + i) % p.len];
    for (0..p.len) |i| p[i] = tmp[i];
}
fn put_i64(out: [*]u8, offset: *usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |b| { out[offset.*] = @truncate(bits >> @as(u6, @intCast(8 * b))); offset.* += 1; }
}

export fn minkowski_sum_convex_polygons(input_opt: ?[*]const i64, length: usize,
    output_opt: ?[*]u8, capacity: usize) i64 {
    if (input_opt == null or length < 14 or length > MAX_INPUT) return -1;
    const input = input_opt.?;
    if (input[0] < 3 or input[0] > 32 or input[1] < 3 or input[1] > 32) return -1;
    const pn: usize = @intCast(input[0]); const qn: usize = @intCast(input[1]);
    if (length != 2 + 2 * pn + 2 * qn) return -1;
    var p: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var q: [MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var sums: [2 * MAX_VERTICES]Point = @splat(.{ .x = 0, .y = 0 });
    var at: usize = 2;
    for (0..pn) |i| {
        p[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (p[i].x < -MAX_COORD or p[i].x > MAX_COORD or p[i].y < -MAX_COORD or p[i].y > MAX_COORD) return -1;
    }
    for (0..qn) |i| {
        q[i] = .{ .x = input[at], .y = input[at + 1] }; at += 2;
        if (q[i].x < -MAX_COORD or q[i].x > MAX_COORD or q[i].y < -MAX_COORD or q[i].y > MAX_COORD) return -1;
    }
    if (!valid_polygon(p[0..pn]) or !valid_polygon(q[0..qn])) return -1;
    rotate_lowest(p[0..pn]); rotate_lowest(q[0..qn]);
    var i: usize = 0; var j: usize = 0; var count: usize = 0;
    while (i < pn or j < qn) {
        sums[count] = .{ .x = p[i % pn].x + q[j % qn].x, .y = p[i % pn].y + q[j % qn].y };
        count += 1;
        if (i == pn) { j += 1; continue; }
        if (j == qn) { i += 1; continue; }
        const order = angle_compare(edge(p[0..pn], i), edge(q[0..qn], j));
        if (order <= 0) i += 1;
        if (order >= 0) j += 1;
    }
    const needed = (1 + 2 * count) * 8;
    if (needed > capacity or output_opt == null) return -2;
    const output = output_opt.?;
    var offset: usize = 0;
    put_i64(output, &offset, @intCast(count));
    for (0..count) |k| { put_i64(output, &offset, sums[k].x); put_i64(output, &offset, sums[k].y); }
    return @intCast(needed);
}
