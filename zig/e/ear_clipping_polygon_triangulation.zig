const max_vertices: usize = 64;
const coordinate_limit: i64 = 10_000;

const Point = struct { x: i64, y: i64 };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn onSegment(a: Point, b: Point, p: Point) bool {
    return cross(a, b, p) == 0 and @min(a.x, b.x) <= p.x and p.x <= @max(a.x, b.x) and
        @min(a.y, b.y) <= p.y and p.y <= @max(a.y, b.y);
}

fn segmentsIntersect(a: Point, b: Point, c: Point, d: Point) bool {
    const ab_c = cross(a, b, c);
    const ab_d = cross(a, b, d);
    const cd_a = cross(c, d, a);
    const cd_b = cross(c, d, b);
    if (((ab_c > 0 and ab_d < 0) or (ab_c < 0 and ab_d > 0)) and
        ((cd_a > 0 and cd_b < 0) or (cd_a < 0 and cd_b > 0))) return true;
    return (ab_c == 0 and onSegment(a, b, c)) or (ab_d == 0 and onSegment(a, b, d)) or
        (cd_a == 0 and onSegment(c, d, a)) or (cd_b == 0 and onSegment(c, d, b));
}

fn pointInTriangle(a: Point, b: Point, c: Point, p: Point, winding: i64) bool {
    const ab = cross(a, b, p) * winding;
    const bc = cross(b, c, p) * winding;
    const ca = cross(c, a, p) * winding;
    return ab >= 0 and bc >= 0 and ca >= 0;
}

fn writeU32(output: [*c]u8, offset: usize, value: u32) void {
    for (0..4) |byte| output[offset + byte] = @truncate(value >> @intCast(8 * byte));
}

// Triangulate a simple polygon into original vertex indices using deterministic ear clipping.
export fn ear_clipping_polygon_triangulation(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 6 or length > 2 * max_vertices or length % 2 != 0) return -1;
    const count = length / 2;
    var points: [max_vertices]Point = undefined;
    for (0..count) |index| {
        const x = values[2 * index];
        const y = values[2 * index + 1];
        if (x < -coordinate_limit or x > coordinate_limit or y < -coordinate_limit or y > coordinate_limit) return -1;
        points[index] = .{ .x = x, .y = y };
        for (0..index) |previous| {
            if (points[previous].x == x and points[previous].y == y) return -1;
        }
    }

    var area_twice: i64 = 0;
    for (0..count) |index| {
        const next = (index + 1) % count;
        area_twice += points[index].x * points[next].y - points[index].y * points[next].x;
        const after = (index + 2) % count;
        if (cross(points[index], points[next], points[after]) == 0) return -1;
    }
    if (area_twice == 0) return -1;
    for (0..count) |first| {
        const first_next = (first + 1) % count;
        for (first + 1..count) |second| {
            const second_next = (second + 1) % count;
            if (first == second or first_next == second or second_next == first) continue;
            if (segmentsIntersect(points[first], points[first_next], points[second], points[second_next])) return -1;
        }
    }

    const winding: i64 = if (area_twice > 0) 1 else -1;
    var live: [max_vertices]bool = undefined;
    for (0..count) |index| live[index] = true;
    var triangles: [3 * (max_vertices - 2)]u32 = undefined;
    var triangle_count: usize = 0;
    var remaining = count;
    while (remaining > 3) {
        var clipped = false;
        for (0..count) |current| {
            if (!live[current]) continue;
            var previous = (current + count - 1) % count;
            while (!live[previous]) previous = (previous + count - 1) % count;
            var next = (current + 1) % count;
            while (!live[next]) next = (next + 1) % count;
            if (cross(points[previous], points[current], points[next]) * winding <= 0) continue;
            var contains_vertex = false;
            for (0..count) |test| {
                if (!live[test] or test == previous or test == current or test == next) continue;
                if (pointInTriangle(points[previous], points[current], points[next], points[test], winding)) {
                    contains_vertex = true;
                    break;
                }
            }
            if (contains_vertex) continue;
            const offset = triangle_count * 3;
            triangles[offset] = @intCast(previous);
            triangles[offset + 1] = @intCast(current);
            triangles[offset + 2] = @intCast(next);
            triangle_count += 1;
            live[current] = false;
            remaining -= 1;
            clipped = true;
            break;
        }
        if (!clipped) return -1;
    }

    var first: usize = 0;
    while (!live[first]) first += 1;
    var second = (first + 1) % count;
    while (!live[second]) second = (second + 1) % count;
    var third = (second + 1) % count;
    while (!live[third]) third = (third + 1) % count;
    const final_offset = triangle_count * 3;
    triangles[final_offset] = @intCast(first);
    triangles[final_offset + 1] = @intCast(second);
    triangles[final_offset + 2] = @intCast(third);
    triangle_count += 1;

    const required = triangle_count * 12;
    if (output == null or output_capacity < required) return -2;
    for (0..triangle_count * 3) |index| writeU32(output, index * 4, triangles[index]);
    return @intCast(triangle_count);
}
