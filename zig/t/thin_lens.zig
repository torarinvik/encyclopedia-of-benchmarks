const INVALID_RESULT: f64 = -1.0e300;

/// Bounded selector wrapper for the Java thin-lens operations.
export fn thin_lens(values: [*]const i64, length: usize) f64 {
    if (length != 3) return INVALID_RESULT;
    const operation = values[0];
    const a = values[1];
    const b = values[2];
    if (a < -1000 or a > 1000 or b < -1000 or b > 1000) return INVALID_RESULT;
    if (operation == 0) {
        if (a == 0 or b == 0 or a == b) return INVALID_RESULT;
        const f: f64 = @floatFromInt(a);
        const u: f64 = @floatFromInt(b);
        return 1.0 / ((1.0 / f) - (1.0 / u));
    }
    if (operation == 1) {
        if (b == 0) return INVALID_RESULT;
        return @as(f64, @floatFromInt(a)) / @as(f64, @floatFromInt(b));
    }
    if (operation == 2) {
        if (b != 0) return INVALID_RESULT;
        return if (a > 0) 1.0 else 0.0;
    }
    return INVALID_RESULT;
}
