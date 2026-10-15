const max_axis: i64 = 100;

fn writeI32(output: [*c]u8, position: usize, value: i64) void {
    const bits: u32 = @bitCast(@as(i32, @intCast(value)));
    for (0..4) |byte| output[position * 4 + byte] = @truncate(bits >> @intCast(byte * 8));
}

fn emitPoint(output: [*c]u8, count: *usize, x: i64, y: i64) void {
    if (output != null) {
        writeI32(output, 2 * count.*, x);
        writeI32(output, 2 * count.* + 1, y);
    }
    count.* += 1;
}

fn emitSymmetric(output: [*c]u8, count: *usize, cx: i64, cy: i64, x: i64, y: i64) void {
    emitPoint(output, count, cx + x, cy + y);
    emitPoint(output, count, cx - x, cy + y);
    emitPoint(output, count, cx + x, cy - y);
    emitPoint(output, count, cx - x, cy - y);
}

fn rasterize(output: [*c]u8, cx: i64, cy: i64, a: i64, b: i64) usize {
    var count: usize = 0;
    if (a == 0 and b == 0) {
        emitPoint(output, &count, cx, cy);
        return count;
    }
    if (a == 0) {
        var y = cy - b;
        while (y <= cy + b) : (y += 1) emitPoint(output, &count, cx, y);
        return count;
    }
    if (b == 0) {
        var x = cx - a;
        while (x <= cx + a) : (x += 1) emitPoint(output, &count, x, cy);
        return count;
    }

    var x: i64 = 0;
    var y = b;
    const a_squared = a * a;
    const b_squared = b * b;
    var d1 = @as(f64, @floatFromInt(b_squared)) - @as(f64, @floatFromInt(a_squared * b)) +
        0.25 * @as(f64, @floatFromInt(a_squared));
    var dx: f64 = 2.0 * @as(f64, @floatFromInt(b_squared)) * @as(f64, @floatFromInt(x));
    var dy: f64 = 2.0 * @as(f64, @floatFromInt(a_squared)) * @as(f64, @floatFromInt(y));
    while (dx < dy) {
        emitSymmetric(output, &count, cx, cy, x, y);
        if (d1 < 0.0) {
            x += 1;
            dx += 2.0 * @as(f64, @floatFromInt(b_squared));
            d1 += dx + @as(f64, @floatFromInt(b_squared));
        } else {
            x += 1;
            y -= 1;
            dx += 2.0 * @as(f64, @floatFromInt(b_squared));
            dy -= 2.0 * @as(f64, @floatFromInt(a_squared));
            d1 += dx - dy + @as(f64, @floatFromInt(b_squared));
        }
    }
    var d2 = @as(f64, @floatFromInt(b_squared)) * (@as(f64, @floatFromInt(x)) + 0.5) *
        (@as(f64, @floatFromInt(x)) + 0.5) +
        @as(f64, @floatFromInt(a_squared * (y - 1) * (y - 1))) -
        @as(f64, @floatFromInt(a_squared * b_squared));
    while (y >= 0) {
        emitSymmetric(output, &count, cx, cy, x, y);
        if (d2 > 0.0) {
            y -= 1;
            dy -= 2.0 * @as(f64, @floatFromInt(a_squared));
            d2 += @as(f64, @floatFromInt(a_squared)) - dy;
        } else {
            y -= 1;
            x += 1;
            dx += 2.0 * @as(f64, @floatFromInt(b_squared));
            dy -= 2.0 * @as(f64, @floatFromInt(a_squared));
            d2 += dx - dy + @as(f64, @floatFromInt(a_squared));
        }
    }
    return count;
}

// Plot midpoint ellipse points in the source algorithm's region and quadrant order.
export fn midpoint_ellipse(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 4 or values[0] < -10_000 or values[0] > 10_000 or
        values[1] < -10_000 or values[1] > 10_000 or values[2] < 0 or values[2] > max_axis or
        values[3] < 0 or values[3] > max_axis) return -1;
    const count = rasterize(null, values[0], values[1], values[2], values[3]);
    if (output == null or output_capacity < count * 8) return -2;
    _ = rasterize(output, values[0], values[1], values[2], values[3]);
    return @intCast(count);
}
