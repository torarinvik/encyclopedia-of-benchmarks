const std = @import("std");

const INVALID_RESULT: f64 = -1.0e300;

fn roundFiveEven(value: f64) f64 {
    const scaled = value * 100000.0;
    const fraction = scaled - @floor(scaled);
    if (@abs(fraction - 0.5) <= 1.0e-7) return INVALID_RESULT;
    if (value == 0.0) return value;
    const negative = value < 0.0;
    var normalized = @abs(value);
    var exponent: i32 = 0;
    while (normalized < 1.0) { normalized *= 2.0; exponent -= 1; }
    while (normalized >= 2.0) { normalized *= 0.5; exponent += 1; }
    const mantissa: u64 = @intFromFloat(normalized * 4503599627370496.0);
    const shift = 52 - exponent;
    if (shift > 70) return if (negative) -0.0 else 0.0;
    const low_product = (mantissa & 0xffffffff) * 100000;
    const high_product = (mantissa >> 32) * 100000;
    const shifted_high = high_product << 32;
    const low = low_product +% shifted_high;
    const high = (high_product >> 32) + @as(u64, @intFromBool(low < low_product));
    const quotient: u64 = if (shift < 64)
        (low >> @intCast(shift)) | (high << @intCast(64 - shift))
    else
        high >> @intCast(shift - 64);
    const half_bit: u64 = if (shift - 1 < 64)
        (low >> @intCast(shift - 1)) & 1
    else
        (high >> @intCast(shift - 65)) & 1;
    const lower_bits = if (shift - 1 < 64)
        (low & ((@as(u64, 1) << @intCast(shift - 1)) - 1)) != 0
    else
        low != 0 or (high & ((@as(u64, 1) << @intCast(shift - 65)) - 1)) != 0;
    const rounded = quotient + @as(u64, @intFromBool(half_bit != 0 and (lower_bits or (quotient & 1) != 0)));
    const result = @as(f64, @floatFromInt(rounded)) / 100000.0;
    return if (negative) -result else result;
}

export fn light_aberration(values: ?[*]const i64, length: usize) f64 {
    if (values == null or length != 2) return INVALID_RESULT;
    const input = values.?;
    const theta_code = input[0];
    const beta_code = input[1];
    if (theta_code < -3141592 or theta_code > 3141592 or beta_code < 0 or beta_code > 999999) return INVALID_RESULT;
    const theta = @as(f64, @floatFromInt(theta_code)) / 1000000.0;
    const beta = @as(f64, @floatFromInt(beta_code)) / 1000000.0;
    const factor = @sqrt((1.0 - beta) / (1.0 + beta));
    const angle = 2.0 * std.math.atan(factor * @tan(theta / 2.0));
    return roundFiveEven(angle);
}
