const INVALID_RESULT: f64 = -1.0e300;

fn objective(x: f64) f64 { return x * x - 3.0; }

export fn secant(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 5) return INVALID_RESULT;
    if (values[0] != 0 or values[1] < 1_000_000 or values[1] > 1_500_000 or
        values[2] < 1_600_000 or values[2] > 2_000_000 or values[1] >= values[2] or
        values[3] < 1 or values[3] > 100_000 or values[4] < 0 or values[4] > 32) return INVALID_RESULT;
    var x0: f64 = @as(f64, @floatFromInt(values[1])) / 1_000_000.0;
    var x1: f64 = @as(f64, @floatFromInt(values[2])) / 1_000_000.0;
    const tolerance = @as(f64, @floatFromInt(values[3])) / 1_000_000_000.0;
    const max_updates: usize = @intCast(values[4]);
    for (0..max_updates + 1) |update| {
        const f1 = objective(x1);
        if (@abs(f1) <= tolerance) return x1;
        if (update == max_updates) break;
        const f0 = objective(x0);
        const denominator = f1 - f0;
        if (denominator == 0.0) return INVALID_RESULT;
        const x2 = x1 - f1 * (x1 - x0) / denominator;
        if (!@import("std").math.isFinite(x2)) return INVALID_RESULT;
        x0 = x1;
        x1 = x2;
    }
    return INVALID_RESULT;
}
