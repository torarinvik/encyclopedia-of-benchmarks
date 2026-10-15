export fn decimal_isolate(input: f64) f64 {
    if (!(input > 0.0 and input <= 999_999.0)) return -1.0;
    const scaled_value = input * 10_000.0;
    const scaled: i64 = @intFromFloat(scaled_value);
    if (@as(f64, @floatFromInt(scaled)) != scaled_value or
        @as(f64, @floatFromInt(scaled)) / 10_000.0 != input) return -1.0;
    if (@rem(scaled, 625) != 0 or @rem(scaled, 10_000) == 0) return -1.0;
    return @as(f64, @floatFromInt(@rem(scaled, 10_000))) / 10_000.0;
}
