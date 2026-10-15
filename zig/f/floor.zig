/// Floor for bounded finite binary64 inputs, correcting truncation below zero.
export fn floor(value: f64) f64 {
    if (value < -1_000_000.0 or value > 1_000_000.0) return -1.0;
    var result: i64 = @intFromFloat(value);
    if (value < @as(f64, @floatFromInt(result))) result -= 1;
    return @floatFromInt(result);
}
