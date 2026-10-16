/// Return an integer Jarvis-scan hull in counter-clockwise order.
const MAX_POINTS: usize = 64;
const MIN_COORDINATE: i64 = -10000;
const MAX_COORDINATE: i64 = 10000;

fn orientation(a: [2]i64, b: [2]i64, c: [2]i64) i64 {
    return (b[0] - a[0]) * (c[1] - a[1]) - (b[1] - a[1]) * (c[0] - a[0]);
}

fn put_i64(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

export fn jarvis_scan(input: ?[*]const i64, length: usize, output: ?[*]u8, capacity: usize) i64 {
    if (input == null or length < 1) return -1;
    const input_values = input.?;
    if (input_values[0] < 0 or input_values[0] > MAX_POINTS) return -1;
    const count: usize = @intCast(input_values[0]);
    if (length != 1 + 2 * count) return -1;

    var points: [MAX_POINTS][2]i64 = undefined;
    for (0..count) |point| {
        points[point] = .{ input_values[1 + 2 * point], input_values[2 + 2 * point] };
        if (points[point][0] < MIN_COORDINATE or points[point][0] > MAX_COORDINATE or
            points[point][1] < MIN_COORDINATE or points[point][1] > MAX_COORDINATE) return -1;
    }
    if (count <= 2) return 0;
    for (0..count) |first| {
        for (first + 1..count) |second| {
            if (points[first][0] == points[second][0] and points[first][1] == points[second][1]) return -1;
        }
    }
    for (0..count - 2) |first| {
        for (first + 1..count - 1) |second| {
            for (second + 1..count) |third| {
                if (orientation(points[first], points[second], points[third]) == 0) return -1;
            }
        }
    }

    var start: usize = 0;
    for (1..count) |point| {
        if (points[point][0] < points[start][0] or
            (points[point][0] == points[start][0] and points[point][1] < points[start][1])) start = point;
    }
    var hull: [MAX_POINTS]usize = @splat(0);
    var hull_count: usize = 0;
    var current = start;
    while (true) {
        if (hull_count == count) return -1;
        hull[hull_count] = current;
        hull_count += 1;
        var candidate = (current + 1) % count;
        for (0..count) |point| {
            if (orientation(points[current], points[point], points[candidate]) > 0) candidate = point;
        }
        if (candidate == start) break;
        current = candidate;
    }
    const bytes = hull_count * 16;
    if (output == null or capacity < bytes) return -2;
    const output_bytes = output.?;
    for (0..hull_count) |index| {
        put_i64(output_bytes, index * 16, points[hull[index]][0]);
        put_i64(output_bytes, index * 16 + 8, points[hull[index]][1]);
    }
    return @intCast(bytes);
}
