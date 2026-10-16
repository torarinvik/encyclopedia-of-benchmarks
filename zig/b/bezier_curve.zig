const MAX_POINTS: usize = 16;

fn integerPower(base: f64, exponent: usize) f64 {
    var result: f64 = 1.0;
    for (0..exponent) |_| result *= base;
    return result;
}

fn choose(n: usize, k_input: usize) u64 {
    const k = @min(k_input, n - k_input);
    var result: u64 = 1;
    for (1..k + 1) |index| result = result * (n - k + index) / index;
    return result;
}

fn roundScaled(value: f64) i64 {
    const scaled = value * 1_000_000.0;
    return @intFromFloat(if (scaled >= 0.0) scaled + 0.5 else scaled - 0.5);
}

fn writeI64Le(output: [*]u8, offset: usize, value: i64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[offset + byte] = @truncate(bits >> @intCast(8 * byte));
}

export fn bezier_curve(values: [*c]const i64, length: usize, output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length < 4 or length > 34) return -1;
    const point_count_value = values[0];
    const parameter_q = values[1];
    if (point_count_value < 1 or point_count_value > MAX_POINTS or parameter_q < 0 or parameter_q > 1_000_000) return -1;
    const point_count: usize = @intCast(point_count_value);
    if (length != 2 + 2 * point_count) return -1;
    for (2..length) |index| if (values[index] < -1_000_000 or values[index] > 1_000_000) return -1;
    if (output == null or output_capacity < 32) return -2;

    const degree = point_count - 1;
    const t: f64 = @as(f64, @floatFromInt(parameter_q)) / 1_000_000.0;
    var x: f64 = 0.0;
    var y: f64 = 0.0;
    var dx: f64 = 0.0;
    var dy: f64 = 0.0;
    for (0..point_count) |index| {
        const weight = @as(f64, @floatFromInt(choose(degree, index))) *
            integerPower(1.0 - t, degree - index) * integerPower(t, index);
        x += weight * @as(f64, @floatFromInt(values[2 + 2 * index]));
        y += weight * @as(f64, @floatFromInt(values[3 + 2 * index]));
    }
    for (0..degree) |index| {
        const weight = @as(f64, @floatFromInt(degree)) * @as(f64, @floatFromInt(choose(degree - 1, index))) *
            integerPower(1.0 - t, degree - 1 - index) * integerPower(t, index);
        dx += weight * @as(f64, @floatFromInt(values[4 + 2 * index] - values[2 + 2 * index]));
        dy += weight * @as(f64, @floatFromInt(values[5 + 2 * index] - values[3 + 2 * index]));
    }
    writeI64Le(output, 0, roundScaled(x));
    writeI64Le(output, 8, roundScaled(y));
    writeI64Le(output, 16, roundScaled(dx));
    writeI64Le(output, 24, roundScaled(dy));
    return 32;
}
