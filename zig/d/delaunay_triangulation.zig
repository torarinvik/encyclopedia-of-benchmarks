const MAX_POINTS: usize = 8;
const MAX_VERTICES: usize = 11;
const MAX_WORK_TRIANGLES: usize = 17;
const MAX_WORK_EDGES: usize = 51;
const MAX_TRIANGLES: usize = 11;
const MAX_OUTPUT_BYTES: usize = 272;
const CIRCUMCIRCLE_EPSILON: f64 = 1e-4;

const Point = struct { x: f64 = 0, y: f64 = 0 };
const Edge = struct { a: usize = 0, b: usize = 0 };
const Triangle = struct { a: usize = 0, b: usize = 0, c: usize = 0, cx: f64 = 0, cy: f64 = 0, radius_squared: f64 = 0 };

fn orient(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64) i64 {
    return (bx - ax) * (cy - ay) - (by - ay) * (cx - ax);
}
fn incircle(ax: i64, ay: i64, bx: i64, by: i64, cx: i64, cy: i64, dx: i64, dy: i64) i64 {
    const x1 = ax - dx; const y1 = ay - dy;
    const x2 = bx - dx; const y2 = by - dy;
    const x3 = cx - dx; const y3 = cy - dy;
    const q1 = x1 * x1 + y1 * y1;
    const q2 = x2 * x2 + y2 * y2;
    const q3 = x3 * x3 + y3 * y3;
    return q1 * (x2 * y3 - y2 * x3) - q2 * (x1 * y3 - y1 * x3) + q3 * (x1 * y2 - y1 * x2);
}
fn sameEdge(a: Edge, b: Edge) bool {
    return (a.a == b.a and a.b == b.b) or (a.a == b.b and a.b == b.a);
}
fn makeTriangle(points: *const [MAX_VERTICES]Point, a: usize, b: usize, c: usize) Triangle {
    const p0 = points[a]; const p1 = points[b]; const p2 = points[c];
    const ax = p1.x - p0.x; const ay = p1.y - p0.y;
    const bx = p2.x - p0.x; const by = p2.y - p0.y;
    const m = p1.x * p1.x - p0.x * p0.x + p1.y * p1.y - p0.y * p0.y;
    const u = p2.x * p2.x - p0.x * p0.x + p2.y * p2.y - p0.y * p0.y;
    const scale = 1.0 / (2.0 * (ax * by - ay * bx));
    const cx = ((p2.y - p0.y) * m + (p0.y - p1.y) * u) * scale;
    const cy = ((p0.x - p2.x) * m + (p1.x - p0.x) * u) * scale;
    const dx = p0.x - cx; const dy = p0.y - cy;
    return .{ .a = a, .b = b, .c = c, .cx = cx, .cy = cy, .radius_squared = dx * dx + dy * dy };
}
fn sortIndices(a: *usize, b: *usize, c: *usize) void {
    if (a.* > b.*) { const temp = a.*; a.* = b.*; b.* = temp; }
    if (b.* > c.*) { const temp = b.*; b.* = c.*; c.* = temp; }
    if (a.* > b.*) { const temp = a.*; a.* = b.*; b.* = temp; }
}
fn triangleLess(a: Triangle, b: Triangle) bool {
    if (a.a != b.a) return a.a < b.a;
    if (a.b != b.b) return a.b < b.b;
    return a.c < b.c;
}
fn putI64(output: *[MAX_OUTPUT_BYTES]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn delaunay_triangulation(values: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (values == null or length < 7 or length > 17) return -1;
    if (values[0] < 3 or values[0] > @as(i64, @intCast(MAX_POINTS))) return -1;
    const n: usize = @intCast(values[0]);
    if (length != 1 + 2 * n) return -1;
    var ix: [MAX_POINTS]i64 = @splat(0);
    var iy: [MAX_POINTS]i64 = @splat(0);
    var points: [MAX_VERTICES]Point = @splat(.{});
    var min_x: i64 = 0; var max_x: i64 = 0; var min_y: i64 = 0; var max_y: i64 = 0;
    for (0..n) |i| {
        const x = values[1 + 2 * i]; const y = values[2 + 2 * i];
        if (x < -10 or x > 10 or y < -10 or y > 10) return -1;
        for (0..i) |j| if (ix[j] == x and iy[j] == y) return -1;
        ix[i] = x; iy[i] = y;
        points[i] = .{ .x = @floatFromInt(x), .y = @floatFromInt(y) };
        if (i == 0) { min_x = x; max_x = x; min_y = y; max_y = y; }
        else { min_x = @min(min_x, x); max_x = @max(max_x, x); min_y = @min(min_y, y); max_y = @max(max_y, y); }
    }
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| {
        if (orient(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c]) == 0) return -1;
    };
    for (0..n) |a| for (a + 1..n) |b| for (b + 1..n) |c| for (c + 1..n) |d| {
        if (incircle(ix[a], iy[a], ix[b], iy[b], ix[c], iy[c], ix[d], iy[d]) == 0) return -1;
    };

    const dmax = @max(max_x - min_x, max_y - min_y);
    const midx = (@as(f64, @floatFromInt(min_x)) + @as(f64, @floatFromInt(max_x))) / 2.0;
    const midy = (@as(f64, @floatFromInt(min_y)) + @as(f64, @floatFromInt(max_y))) / 2.0;
    const s0 = n; const s1 = n + 1; const s2 = n + 2;
    points[s0] = .{ .x = midx - 20.0 * @as(f64, @floatFromInt(dmax)), .y = midy - @as(f64, @floatFromInt(dmax)) };
    points[s1] = .{ .x = midx, .y = midy + 20.0 * @as(f64, @floatFromInt(dmax)) };
    points[s2] = .{ .x = midx + 20.0 * @as(f64, @floatFromInt(dmax)), .y = midy - @as(f64, @floatFromInt(dmax)) };
    for (0..n + 3) |a| for (a + 1..n + 3) |b| for (b + 1..n + 3) |c| {
        const area2 = (points[b].x - points[a].x) * (points[c].y - points[a].y) - (points[b].y - points[a].y) * (points[c].x - points[a].x);
        if (area2 == 0.0) return -1;
    };

    var current: [MAX_WORK_TRIANGLES]Triangle = @splat(.{});
    var next: [MAX_WORK_TRIANGLES]Triangle = @splat(.{});
    var edges: [MAX_WORK_EDGES]Edge = @splat(.{});
    var current_count: usize = 1;
    current[0] = makeTriangle(&points, s0, s1, s2);
    for (0..n) |p| {
        var edge_count: usize = 0;
        var next_count: usize = 0;
        for (0..current_count) |i| {
            const t = current[i];
            const dx = t.cx - points[p].x; const dy = t.cy - points[p].y;
            if (dx * dx + dy * dy - t.radius_squared <= CIRCUMCIRCLE_EPSILON) {
                edges[edge_count] = .{ .a = t.a, .b = t.b };
                edges[edge_count + 1] = .{ .a = t.b, .b = t.c };
                edges[edge_count + 2] = .{ .a = t.a, .b = t.c };
                edge_count += 3;
            } else {
                if (next_count >= MAX_WORK_TRIANGLES) return -1;
                next[next_count] = t;
                next_count += 1;
            }
        }
        var remove: [MAX_WORK_EDGES]bool = @splat(false);
        for (0..edge_count) |i| for (0..edge_count) |j| {
            if (i != j and sameEdge(edges[i], edges[j])) { remove[i] = true; remove[j] = true; }
        };
        for (0..edge_count) |i| {
            if (!remove[i]) {
                if (next_count >= MAX_WORK_TRIANGLES) return -1;
                next[next_count] = makeTriangle(&points, edges[i].a, edges[i].b, p);
                next_count += 1;
            }
        }
        for (0..next_count) |i| current[i] = next[i];
        current_count = next_count;
    }
    var result: [MAX_TRIANGLES]Triangle = @splat(.{});
    var result_count: usize = 0;
    for (0..current_count) |i| {
        var t = current[i];
        if (t.a >= n or t.b >= n or t.c >= n) continue;
        if (result_count >= MAX_TRIANGLES) return -1;
        sortIndices(&t.a, &t.b, &t.c);
        var j = result_count;
        result_count += 1;
        while (j > 0 and triangleLess(t, result[j - 1])) : (j -= 1) result[j] = result[j - 1];
        result[j] = t;
    }
    if (result_count == 0) return -1;
    var staged: [MAX_OUTPUT_BYTES]u8 = @splat(0);
    putI64(&staged, 0, @intCast(result_count));
    for (0..result_count) |i| {
        putI64(&staged, 8 + 24 * i, @intCast(result[i].a));
        putI64(&staged, 16 + 24 * i, @intCast(result[i].b));
        putI64(&staged, 24 + 24 * i, @intCast(result[i].c));
    }
    const required = 8 + 24 * result_count;
    if (output == null or capacity < required) return -2;
    @memcpy(output[0..required], staged[0..required]);
    return @intCast(required);
}
