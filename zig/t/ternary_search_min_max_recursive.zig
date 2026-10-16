const INVALID_RESULT: f64 = -1.0e300;
const Objective = *const fn (f32) f32;

fn minimumFunction(x: f32) f32 { return x * x - 2.0 * x + 3.0; }
fn maximumFunction(x: f32) f32 { return -x * x - 2.0 * x + 3.0; }
fn ternaryMin(f: Objective, start: f32, end: f32, precision: f32) f32 {
    if (@abs(end - start) >= precision) {
        const width = end - start;
        const mid1 = start + width / 3.0;
        const mid2 = end - width / 3.0;
        const r1 = f(mid1);
        const r2 = f(mid2);
        if (r1 < r2) return ternaryMin(f, start, mid2, precision);
        if (r1 > r2) return ternaryMin(f, mid1, end, precision);
        return ternaryMin(f, mid1, mid2, precision);
    }
    return f(start);
}
fn ternaryMax(f: Objective, start: f32, end: f32, precision: f32) f32 {
    if (@abs(end - start) >= precision) {
        const width = end - start;
        const mid1 = start + width / 3.0;
        const mid2 = end - width / 3.0;
        const r1 = f(mid1);
        const r2 = f(mid2);
        if (r1 < r2) return ternaryMax(f, mid1, end, precision);
        if (r1 > r2) return ternaryMax(f, start, mid2, precision);
        return ternaryMax(f, mid1, mid2, precision);
    }
    return f(start);
}

export fn ternary_search_min_max_recursive(values: [*c]const i64, length: usize) f64 {
    if (values == null or length != 4) return INVALID_RESULT;
    const mode = values[0];
    const start_milli = values[1];
    const end_milli = values[2];
    const precision_milli = values[3];
    const center_milli: i64 = if (mode == 0) 1000 else if (mode == 1) -1000 else 0;
    if (mode < 0 or mode > 1 or start_milli < -100000 or end_milli > 100000 or
        start_milli >= center_milli or end_milli <= center_milli or precision_milli < 1 or precision_milli > 8)
        return INVALID_RESULT;
    const start: f32 = @as(f32, @floatFromInt(start_milli)) / 1000.0;
    const end: f32 = @as(f32, @floatFromInt(end_milli)) / 1000.0;
    const precision: f32 = @as(f32, @floatFromInt(precision_milli)) / 1000.0;
    return @as(f64, @floatCast(if (mode == 0)
        ternaryMin(minimumFunction, start, end, precision)
    else
        ternaryMax(maximumFunction, start, end, precision)));
}
