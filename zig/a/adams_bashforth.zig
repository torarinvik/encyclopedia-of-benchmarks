/// Bounded Adams-Bashforth methods for y' = x + y on a quarter-step grid.
fn coefficient(order: i64, offset: usize) i64 {
    if (order == 2) return if (offset == 0) 3 else -1;
    if (order == 3) return if (offset == 0) 23 else if (offset == 1) -16 else 5;
    if (order == 4) return if (offset == 0) 55 else if (offset == 1) -59 else if (offset == 2) 37 else -9;
    return if (offset == 0) 1901 else if (offset == 1) -2774 else if (offset == 2) -2616 else if (offset == 3) -1274 else 251;
}

fn appendInteger(valueInput: i64, output: [*]u8, positionInput: usize) usize {
    var value = valueInput;
    var digits: [24]u8 = undefined;
    var count: usize = 0;
    var position = positionInput;
    if (value < 0) { output[position] = '-'; position += 1; value = -value; }
    while (true) {
        digits[count] = @intCast(@rem(value, 10));
        count += 1;
        value = @divTrunc(value, 10);
        if (value == 0) break;
    }
    while (count > 0) {
        count -= 1;
        output[position] = '0' + digits[count];
        position += 1;
    }
    return position;
}

export fn adams_bashforth(values: [*]const i64, length: usize,
                          output: [*]u8, output_capacity: usize) i64 {
    if (length < 4) return -1;
    const order = values[0];
    const steps = values[1];
    if (order < 2 or order > 5 or steps < 1 or steps > 4 or length != @as(usize, @intCast(order + 2))) return -1;
    var x: [14]f64 = @splat(0.0);
    var y: [14]f64 = @splat(0.0);
    for (0..@intCast(order)) |i| {
        if (values[i + 2] < -100000 or values[i + 2] > 100000) return -1;
        x[i] = @as(f64, @floatFromInt(i)) * 0.25;
        y[i] = @as(f64, @floatFromInt(values[i + 2])) / 100000.0;
    }
    const denominator: f64 = if (order == 2) 2.0 else if (order == 3) 12.0 else if (order == 4) 24.0 else 720.0;
    var iterations: usize = @intCast(steps);
    if (order == 3 or order == 5) iterations += 1;
    var count: usize = @intCast(order);
    for (0..iterations) |_| {
        var weighted: f64 = 0.0;
        for (0..@intCast(order)) |offset| {
            const current = count - 1 - offset;
            weighted += @as(f64, @floatFromInt(coefficient(order, offset))) * (x[current] + y[current]);
        }
        y[count] = y[count - 1] + (0.25 / denominator) * weighted;
        x[count] = x[count - 1] + 0.25;
        count += 1;
    }
    var encoded: [256]u8 = undefined;
    var position: usize = 0;
    for (0..count) |i| {
        if (i > 0) { encoded[position] = ','; position += 1; }
        position = appendInteger(@intFromFloat(y[i] * 1000000.0), &encoded, position);
    }
    if (output_capacity < position) return -2;
    for (0..position) |i| output[i] = encoded[i];
    return @intCast(position);
}
