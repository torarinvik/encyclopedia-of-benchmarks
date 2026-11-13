const max_lines: usize = 32;
const max_queries: usize = 32;
const max_length: usize = 99;
const invalid: i64 = -9223372036854775807 - 1;

const Line = struct { slope: i64, intercept: i64 };

fn lineValue(line: Line, x: i64) i64 { return line.slope * x + line.intercept; }

fn redundant(a: Line, b: Line, c: Line) bool {
    return (b.intercept - a.intercept) * (b.slope - c.slope)
        >= (c.intercept - b.intercept) * (a.slope - b.slope);
}

export fn monotone_convex_hull_trick(values: ?[*]const i64, length: usize) i64 {
    if (values == null or length < 2 or length > max_length) return invalid;
    const packed = values.?;
    if (packed[0] < 1 or packed[0] > @as(i64, @intCast(max_lines))
        or packed[1] < 0 or packed[1] > @as(i64, @intCast(max_queries))) return invalid;
    const line_count: usize = @intCast(packed[0]);
    const query_count: usize = @intCast(packed[1]);
    if (length != 2 + 2 * line_count + query_count) return invalid;

    var hull: [max_lines]Line = undefined;
    var hull_count: usize = 0;
    var previous_slope: i64 = 9223372036854775807;
    var cursor: usize = 2;
    for (0..line_count) |_| {
        const line = Line{ .slope = packed[cursor], .intercept = packed[cursor + 1] };
        cursor += 2;
        if (line.slope < -1000 or line.slope > 1000 or line.intercept < -10000 or line.intercept > 10000 or line.slope >= previous_slope) return invalid;
        previous_slope = line.slope;
        while (hull_count >= 2 and redundant(hull[hull_count - 2], hull[hull_count - 1], line)) hull_count -= 1;
        hull[hull_count] = line;
        hull_count += 1;
    }

    var front: usize = 0;
    var previous_x: i64 = -9223372036854775807 - 1;
    var checksum: i64 = 0;
    for (0..query_count) |i| {
        const x = packed[cursor + i];
        if (x < -1000 or x > 1000 or (i > 0 and x < previous_x)) return invalid;
        previous_x = x;
        while (front + 1 < hull_count and lineValue(hull[front + 1], x) <= lineValue(hull[front], x)) front += 1;
        checksum += @as(i64, @intCast(i + 1)) * lineValue(hull[front], x);
    }
    return checksum;
}
