const INVALID_RESULT: f64 = -1.0e300;

export fn sum_of_arithmetic_series(packed: [*]const i64, length: usize) f64 {
    if (length != 3) return INVALID_RESULT;
    const a = packed[0];
    const d = packed[1];
    const n = packed[2];
    if (a < -1000 or a > 1000 or d < -1000 or d > 1000 or n < 1 or n > 1000) return INVALID_RESULT;
    const result = n * (2 * a + (n - 1) * d) / 2;
    return @as(f64, @floatFromInt(result));
}
