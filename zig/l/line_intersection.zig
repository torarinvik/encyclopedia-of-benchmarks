const Point = struct { x: i64, y: i64 };
fn same(a: Point, b: Point) bool { return a.x == b.x and a.y == b.y; }
fn cross(a: Point, b: Point, c: Point) i64 {
    return (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
}
fn onSegment(a: Point, b: Point, p: Point) bool {
    return cross(a, b, p) == 0 and @min(a.x, b.x) <= p.x and p.x <= @max(a.x, b.x) and
        @min(a.y, b.y) <= p.y and p.y <= @max(a.y, b.y);
}
fn writePoint(output: [*c]u8, capacity: usize, x: f64, y: f64) i64 {
    if (output == null or capacity < 16) return -2;
    const x_bits: u64 = @bitCast(x);
    const y_bits: u64 = @bitCast(y);
    for (0..8) |byte| {
        output[byte] = @truncate(x_bits >> @intCast(8 * byte));
        output[8 + byte] = @truncate(y_bits >> @intCast(8 * byte));
    }
    return 1;
}

export fn line_intersection(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (length != 9 or values == null) return -1;
    for (0..8) |index| if (values[index] < -10_000 or values[index] > 10_000) return -1;
    if (values[8] != 0 and values[8] != 1) return -1;
    const p1 = Point{ .x = values[0], .y = values[1] };
    const p2 = Point{ .x = values[2], .y = values[3] };
    const q1 = Point{ .x = values[4], .y = values[5] };
    const q2 = Point{ .x = values[6], .y = values[7] };
    const segments = values[8] == 1;
    const p_point = same(p1, p2);
    const q_point = same(q1, q2);
    if (!segments and (p_point or q_point)) return -1;
    if (segments and p_point and q_point)
        return if (same(p1, q1)) writePoint(output, output_capacity, @floatFromInt(p1.x), @floatFromInt(p1.y)) else 0;
    if (segments and p_point)
        return if (onSegment(q1, q2, p1)) writePoint(output, output_capacity, @floatFromInt(p1.x), @floatFromInt(p1.y)) else 0;
    if (segments and q_point)
        return if (onSegment(p1, p2, q1)) writePoint(output, output_capacity, @floatFromInt(q1.x), @floatFromInt(q1.y)) else 0;
    const denominator = (p1.x - p2.x) * (q1.y - q2.y) - (p1.y - p2.y) * (q1.x - q2.x);
    if (denominator == 0) return 0;
    const determinant_p = p1.x * p2.y - p1.y * p2.x;
    const determinant_q = q1.x * q2.y - q1.y * q2.x;
    const numerator_x = determinant_p * (q1.x - q2.x) - (p1.x - p2.x) * determinant_q;
    const numerator_y = determinant_p * (q1.y - q2.y) - (p1.y - p2.y) * determinant_q;
    if (segments) {
        const den = @abs(denominator);
        const x = if (denominator < 0) -numerator_x else numerator_x;
        const y = if (denominator < 0) -numerator_y else numerator_y;
        const min_x = @max(@min(p1.x, p2.x), @min(q1.x, q2.x));
        const max_x = @min(@max(p1.x, p2.x), @max(q1.x, q2.x));
        const min_y = @max(@min(p1.y, p2.y), @min(q1.y, q2.y));
        const max_y = @min(@max(p1.y, p2.y), @max(q1.y, q2.y));
        if (x < min_x * den or x > max_x * den or y < min_y * den or y > max_y * den) return 0;
        return writePoint(output, output_capacity, @as(f64, @floatFromInt(x)) / @as(f64, @floatFromInt(den)),
            @as(f64, @floatFromInt(y)) / @as(f64, @floatFromInt(den)));
    }
    return writePoint(output, output_capacity,
        @as(f64, @floatFromInt(numerator_x)) / @as(f64, @floatFromInt(denominator)),
        @as(f64, @floatFromInt(numerator_y)) / @as(f64, @floatFromInt(denominator)));
}
