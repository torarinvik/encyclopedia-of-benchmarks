const GRAVITY: f64 = 9.80665;
const OUTPUT_BYTES: i64 = 24;

fn roundCents(value: f64) i64 {
    const bits: u64 = @bitCast(value);
    const exponent: i32 = @intCast((bits >> 52) & 2047);
    if (exponent == 0) return 0;
    const mantissa: u64 = (1 << 52) | (bits & 4503599627370495);
    const product = mantissa * 25;
    const right_shift = 1073 - exponent;
    if (right_shift >= 59) return 0;
    var rounded = product >> @intCast(right_shift);
    const divisor: u64 = @as(u64, 1) << @intCast(right_shift);
    const remainder = product & (divisor - 1);
    const halfway = divisor >> 1;
    if (remainder > halfway or (remainder == halfway and (rounded & 1) != 0)) rounded += 1;
    if ((bits >> 63) != 0) return -@as(i64, @intCast(rounded));
    return @intCast(rounded);
}

fn storeF64Le(output: [*c]u8, offset: usize, value: f64) void {
    var bits: u64 = @bitCast(value);
    for (0..8) |byte| {
        output[offset + byte] = @intCast(bits & 255);
        bits >>= 8;
    }
}

export fn horizontal_projectile_motion(values: [*c]const i64, length: usize,
    output: [*c]u8, output_capacity: usize) i64 {
    if (values == null or length != 2) return -1;
    const velocity_milli = values[0];
    const angle_millidegrees = values[1];
    if (velocity_milli < 0 or velocity_milli > 100000 or
        angle_millidegrees < 1000 or angle_millidegrees > 90000) return -1;
    if (output == null or output_capacity < 24) return -2;

    const velocity: f64 = @as(f64, @floatFromInt(velocity_milli)) / 1000.0;
    const angle: f64 = @as(f64, @floatFromInt(angle_millidegrees)) / 1000.0;
    const pi_over_180 = 3.14159265358979323846264338327950288 / 180.0;
    const distance_raw = velocity * velocity * @sin((2.0 * angle) * pi_over_180) / GRAVITY;
    const angle_sine = @sin(angle * pi_over_180);
    const height_raw = velocity * velocity * angle_sine * angle_sine / (2.0 * GRAVITY);
    const time_raw = (2.0 * velocity) * angle_sine / GRAVITY;
    storeF64Le(output, 0, @as(f64, @floatFromInt(roundCents(distance_raw))) / 100.0);
    storeF64Le(output, 8, @as(f64, @floatFromInt(roundCents(height_raw))) / 100.0);
    storeF64Le(output, 16, @as(f64, @floatFromInt(roundCents(time_raw))) / 100.0);
    return OUTPUT_BYTES;
}
