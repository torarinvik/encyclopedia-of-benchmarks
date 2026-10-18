const MAX_N: i64 = 16;
const MIN_BOUND: i64 = -10_000_000;
const MAX_BOUND: i64 = 10_000_000;
const MAX_UNIFORM: i64 = 999_999;
const INVALID_RESULT: f64 = -1.0e300;

export fn monte_carlo_integration(packed: ?[*]const i64, length: usize) f64 {
    if (packed == null or length < 3 or length > 12) return INVALID_RESULT;
    const values = packed.?;
    const n = values[2];
    if (n < 1 or n > MAX_N or length != @as(usize, @intCast(3 + (n + 1) / 2))) return INVALID_RESULT;
    const a_raw = values[0];
    const b_raw = values[1];
    if (a_raw < MIN_BOUND or a_raw > MAX_BOUND or b_raw < MIN_BOUND or b_raw > MAX_BOUND or a_raw >= b_raw) return INVALID_RESULT;
    for (3..length) |index| {
        if (values[index] < 0 or values[index] > MAX_UNIFORM) return INVALID_RESULT;
    }

    const a = @as(f64, @floatFromInt(a_raw)) / 1_000_000.0;
    const b = @as(f64, @floatFromInt(b_raw)) / 1_000_000.0;
    const interval = b - a;
    var total: f64 = 0.0;
    for (0..@as(usize, @intCast(n / 2))) |index| {
        const u = @as(f64, @floatFromInt(values[3 + index])) / 1_000_000.0;
        const x1 = a + u * interval;
        const x2 = a + (1.0 - u) * interval;
        total += x1 * x1;
        total += x2 * x2;
    }
    if (n % 2 == 1) {
        const u = @as(f64, @floatFromInt(values[3 + @as(usize, @intCast(n / 2))])) / 1_000_000.0;
        const x = a + u * interval;
        total += x * x;
    }
    return interval * total / @as(f64, @floatFromInt(n));
}
