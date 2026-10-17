const INVALID_RESULT: f64 = -1.0e300;

fn integrand(x: f64) f64 {
    return (@exp(x) / 2.0) * (@cos(x) - @sin(x));
}

export fn rectangular_method(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const a_quarters = values[0];
    const b_quarters = values[1];
    const intervals = values[2];
    const rule = values[3];
    if (a_quarters < -64 or a_quarters >= b_quarters or b_quarters > 64 or
        intervals < 1 or intervals > 64 or
        @rem(b_quarters - a_quarters, intervals) != 0 or
        (rule != 0 and rule != 1)) return INVALID_RESULT;

    const a = @as(f64, @floatFromInt(a_quarters)) / 4.0;
    const b = @as(f64, @floatFromInt(b_quarters)) / 4.0;
    const step = (b - a) / @as(f64, @floatFromInt(intervals));
    var x = a;
    var total: f64 = 0.0;
    for (0..@intCast(intervals)) |_| {
        if (rule == 0) {
            total += integrand(x) * step;
            x += step;
        } else {
            x += step;
            total += integrand(x) * step;
        }
    }
    return total;
}
