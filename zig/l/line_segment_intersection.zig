const Point = struct { x: i64, y: i64 };

fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}

fn onSegment(a: Point, b: Point, p: Point) bool {
    return cross(a, b, p) == 0 and @min(a.x, b.x) <= p.x and p.x <= @max(a.x, b.x) and
        @min(a.y, b.y) <= p.y and p.y <= @max(a.y, b.y);
}

fn sign(value: i64) i8 {
    if (value < 0) return -1;
    if (value > 0) return 1;
    return 0;
}

/// Return one when two finite closed segments intersect, otherwise zero.
export fn line_segment_intersection(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    _ = output;
    _ = output_capacity;
    if (length != 8 or values == null) return -1;
    for (0..8) |index| {
        if (values[index] < -10_000 or values[index] > 10_000) return -1;
    }

    const a = Point{ .x = values[0], .y = values[1] };
    const b = Point{ .x = values[2], .y = values[3] };
    const c = Point{ .x = values[4], .y = values[5] };
    const d = Point{ .x = values[6], .y = values[7] };

    const o1 = cross(a, b, c);
    const o2 = cross(a, b, d);
    const o3 = cross(c, d, a);
    const o4 = cross(c, d, b);
    if (o1 == 0 and onSegment(a, b, c)) return 1;
    if (o2 == 0 and onSegment(a, b, d)) return 1;
    if (o3 == 0 and onSegment(c, d, a)) return 1;
    if (o4 == 0 and onSegment(c, d, b)) return 1;
    return if (sign(o1) * sign(o2) < 0 and sign(o3) * sign(o4) < 0) 1 else 0;
}
