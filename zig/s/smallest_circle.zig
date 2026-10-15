const max_points: usize = 12;
const Circle = struct { x: f64, y: f64, radius: f64 };

fn squaredDistance(x: f64, y: f64, px: i64, py: i64) f64 {
    const dx = x - @as(f64, @floatFromInt(px));
    const dy = y - @as(f64, @floatFromInt(py));
    return dx * dx + dy * dy;
}

fn containsAll(values: [*c]const i64, count: usize, circle: Circle) bool {
    const radius_squared = circle.radius * circle.radius;
    for (0..count) |index| {
        if (squaredDistance(circle.x, circle.y, values[2 * index], values[2 * index + 1]) > radius_squared + 1e-12) return false;
    }
    return true;
}

fn consider(values: [*c]const i64, count: usize, candidate: Circle,
    best: *Circle, has_best: *bool) void {
    if (!containsAll(values, count, candidate)) return;
    if (!has_best.* or candidate.radius <= best.radius) {
        best.* = candidate;
        has_best.* = true;
    }
}

fn writeF64(output: [*c]u8, offset: usize, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(byte * 8));
}

// Return the minimum enclosing circle center and radius as three f64 values.
export fn smallest_circle(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 2 or length > 2 * max_points or length % 2 != 0) return -1;
    const count = length / 2;
    for (0..count) |index| {
        if (values[2 * index] < -100 or values[2 * index] > 100 or
            values[2 * index + 1] < -100 or values[2 * index + 1] > 100) return -1;
    }
    if (output == null or output_capacity < 24) return -2;

    var best = Circle{ .x = 0, .y = 0, .radius = 0 };
    var has_best = false;
    if (count == 1) {
        best = .{ .x = @floatFromInt(values[0]), .y = @floatFromInt(values[1]), .radius = 0 };
        has_best = true;
    }
    for (0..count) |i| {
        if (i + 2 >= count) break;
        var j = i + 1;
        while (j + 1 < count) : (j += 1) {
            var k = j + 1;
            while (k < count) : (k += 1) {
                const xi = values[2 * i]; const yi = values[2 * i + 1];
                const xj = values[2 * j]; const yj = values[2 * j + 1];
                const xk = values[2 * k]; const yk = values[2 * k + 1];
                const denominator = 2 * (xi * (yj - yk) + xj * (yk - yi) + xk * (yi - yj));
                if (denominator == 0) continue;
                const norm_i = xi * xi + yi * yi;
                const norm_j = xj * xj + yj * yj;
                const norm_k = xk * xk + yk * yk;
                const numerator_x = norm_i * (yj - yk) + norm_j * (yk - yi) + norm_k * (yi - yj);
                const numerator_y = norm_i * (xk - xj) + norm_j * (xi - xk) + norm_k * (xj - xi);
                const cx = @as(f64, @floatFromInt(numerator_x)) / @as(f64, @floatFromInt(denominator));
                const cy = @as(f64, @floatFromInt(numerator_y)) / @as(f64, @floatFromInt(denominator));
                const radius = @sqrt(squaredDistance(cx, cy, xi, yi));
                consider(values, count, .{ .x = cx, .y = cy, .radius = radius }, &best, &has_best);
            }
        }
    }
    for (0..count) |i| {
        for (i + 1..count) |j| {
            const cx = (@as(f64, @floatFromInt(values[2 * i])) + @as(f64, @floatFromInt(values[2 * j]))) / 2.0;
            const cy = (@as(f64, @floatFromInt(values[2 * i + 1])) + @as(f64, @floatFromInt(values[2 * j + 1]))) / 2.0;
            const radius = @sqrt(squaredDistance(cx, cy, values[2 * i], values[2 * i + 1]));
            consider(values, count, .{ .x = cx, .y = cy, .radius = radius }, &best, &has_best);
        }
    }
    if (!has_best) return -1;
    writeF64(output, 0, best.x);
    writeF64(output, 8, best.y);
    writeF64(output, 16, best.radius);
    return 1;
}
