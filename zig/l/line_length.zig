const INVALID_RESULT: f64 = -1.0e300;

/// Repeated-step polyline length for the source demo curve sin(10*x).
export fn line_length(x_start: f64, x_end: f64, steps_value: f64) f64 {
    if (x_start != x_start or x_end != x_end or steps_value != steps_value or
        x_start < -10.0 or x_start > 10.0 or x_end < -10.0 or x_end > 10.0 or
        x_start > x_end or steps_value < 1.0 or steps_value > 10000.0) {
        return INVALID_RESULT;
    }
    const steps: usize = @intFromFloat(steps_value);
    if (@as(f64, @floatFromInt(steps)) != steps_value) return INVALID_RESULT;

    var x1 = x_start;
    var fx1 = @sin(10.0 * x_start);
    var length: f64 = 0.0;
    for (0..steps) |_| {
        const x2 = (x_end - x_start) / @as(f64, @floatFromInt(steps)) + x1;
        const fx2 = @sin(10.0 * x2);
        const dx = x2 - x1;
        const dy = fx2 - fx1;
        length += @sqrt(dx * dx + dy * dy);
        x1 = x2;
        fx1 = fx2;
    }
    return length;
}
