/// Incremental floating-point DDA points encoded as little-endian i32 pairs.
fn roundTiesToEven(value: f64) i64 {
    var lower: i64 = @intFromFloat(value);
    if (@as(f64, @floatFromInt(lower)) > value) lower -= 1;
    const fraction = value - @as(f64, @floatFromInt(lower));
    if (fraction > 0.5 or (fraction == 0.5 and lower % 2 != 0)) lower += 1;
    return lower;
}

fn writeI32Le(output: [*]u8, position: *usize, value: i64) void {
    const signed: i32 = @intCast(value);
    const bits: u32 = @bitCast(signed);
    for (0..4) |byte| {
        output[position.*] = @truncate(bits >> @intCast(byte * 8));
        position.* += 1;
    }
}

export fn digital_differential_analyzer_line(values: [*]const i64, length: usize,
                                              output: [*]u8, output_capacity: usize) i64 {
    if (length != 4) return -1;
    for (0..4) |index| if (values[index] < -1_000_000 or values[index] > 1_000_000) return -1;
    const dx = values[2] - values[0];
    const dy = values[3] - values[1];
    const abs_dx = if (dx < 0) -dx else dx;
    const abs_dy = if (dy < 0) -dy else dy;
    const steps = @max(abs_dx, abs_dy);
    if (steps == 0 or steps > 4096) return -1;
    const output_bytes: usize = @intCast(steps * 8);
    if (output_capacity < output_bytes) return -2;
    const x_increment = @as(f64, @floatFromInt(dx)) / @as(f64, @floatFromInt(steps));
    const y_increment = @as(f64, @floatFromInt(dy)) / @as(f64, @floatFromInt(steps));
    var x = @as(f64, @floatFromInt(values[0]));
    var y = @as(f64, @floatFromInt(values[1]));
    var position: usize = 0;
    for (0..@as(usize, @intCast(steps))) |_| {
        x += x_increment;
        y += y_increment;
        writeI32Le(output, &position, roundTiesToEven(x));
        writeI32Le(output, &position, roundTiesToEven(y));
    }
    return @intCast(output_bytes);
}
