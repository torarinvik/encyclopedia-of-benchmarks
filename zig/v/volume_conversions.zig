const INVALID_RESULT: i64 = -1;
const MAX_VALUE: i64 = 1000;

fn unitFactorToCubicMeters(unit: i64) f64 {
    return if (unit == 1) 0.001 else 1.0;
}

fn putF64Le(output: [*c]u8, value: f64) void {
    const bits: u64 = @bitCast(value);
    for (0..8) |byte| output[byte] = @truncate(bits >> @intCast(8 * byte));
}

pub export fn volume_conversions(input: [*c]const i64, length: usize, output: [*c]u8, capacity: usize) i64 {
    if (input == null or length != 3) return INVALID_RESULT;
    const value = input[0];
    const from_unit = input[1];
    const to_unit = input[2];
    if (value < 0 or value > MAX_VALUE or from_unit < 0 or from_unit > 2 or to_unit < 0 or to_unit > 2 or from_unit == to_unit) return INVALID_RESULT;
    if (capacity < 8 or output == null) return -2;
    const cubic_meters = @as(f64, @floatFromInt(value)) * unitFactorToCubicMeters(from_unit);
    const converted = cubic_meters / unitFactorToCubicMeters(to_unit);
    putF64Le(output, converted);
    return 8;
}
