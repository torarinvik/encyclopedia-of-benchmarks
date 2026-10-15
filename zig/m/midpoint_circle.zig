const max_radius: i64 = 1000;

fn writeI32(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[position * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn writePoint(output: [*c]u8, position: usize, x: i64, y: i64) void {
    writeI32(output, 2 * position, x);
    writeI32(output, 2 * position + 1, y);
}

fn groupCount(radius: i64) usize {
    if (radius == 0) return 1;
    var x = radius;
    var y: i64 = 0;
    var decision = 1 - radius;
    var groups: usize = 1;
    while (x > y) {
        y += 1;
        if (decision <= 0) decision += 2 * y + 1 else {
            x -= 1;
            decision += 2 * y - 2 * x + 1;
        }
        groups += 1;
    }
    return groups;
}

fn appendSymmetric(output: [*c]u8, count: *usize, cx: i64, cy: i64, x: i64, y: i64) void {
    writePoint(output, count.*, cx + x, cy + y); count.* += 1;
    writePoint(output, count.*, cx - x, cy + y); count.* += 1;
    writePoint(output, count.*, cx + x, cy - y); count.* += 1;
    writePoint(output, count.*, cx - x, cy - y); count.* += 1;
    writePoint(output, count.*, cx + y, cy + x); count.* += 1;
    writePoint(output, count.*, cx - y, cy + x); count.* += 1;
    writePoint(output, count.*, cx + y, cy - x); count.* += 1;
    writePoint(output, count.*, cx - y, cy - x); count.* += 1;
}

// Plot midpoint-circle points in Java's original order, retaining duplicates.
export fn midpoint_circle(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 3 or values[0] < -10_000 or values[0] > 10_000 or
        values[1] < -10_000 or values[1] > 10_000 or values[2] < 0 or values[2] > max_radius) return -1;
    const radius = values[2];
    const total_points = if (radius == 0) @as(usize, 1) else groupCount(radius) * 8;
    if (output == null or output_capacity < total_points * 8) return -2;
    if (radius == 0) {
        writePoint(output, 0, values[0], values[1]);
        return 1;
    }
    var x = radius;
    var y: i64 = 0;
    var decision = 1 - radius;
    var written: usize = 0;
    appendSymmetric(output, &written, values[0], values[1], x, y);
    while (x > y) {
        y += 1;
        if (decision <= 0) decision += 2 * y + 1 else {
            x -= 1;
            decision += 2 * y - 2 * x + 1;
        }
        appendSymmetric(output, &written, values[0], values[1], x, y);
    }
    return @intCast(written);
}
