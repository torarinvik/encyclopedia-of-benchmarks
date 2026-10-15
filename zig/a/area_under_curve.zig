/// Composite trapezoidal integration for constant, linear, and quadratic samples.
const MAX_STEPS: i64 = 10000;
const MAX_COORD_MILLI: i64 = 100000;
const OUTPUT_SCALE: f64 = 1000000.0;

fn sample_value(function_id: i64, x: f64) f64 {
    return switch (function_id) {
        0 => 5.0,
        1 => x,
        else => x * x,
    };
}

export fn area_under_curve(input: [*]const i64, length: usize) i64 {
    if (length != 4) return -1;
    const function_id = input[0];
    const start_milli = input[1];
    const end_milli = input[2];
    const steps = input[3];
    if (function_id < 0 or function_id > 2 or start_milli < 0 or start_milli > MAX_COORD_MILLI or
        end_milli < 0 or end_milli > MAX_COORD_MILLI or steps < 1 or steps > MAX_STEPS) return -1;
    const low_milli = @min(start_milli, end_milli);
    const high_milli = @max(start_milli, end_milli);
    const start = @as(f64, @floatFromInt(low_milli)) / 1000.0;
    const ending = @as(f64, @floatFromInt(high_milli)) / 1000.0;
    const width = (ending - start) / @as(f64, @floatFromInt(steps));
    var x1 = start;
    var y1 = sample_value(function_id, x1);
    var area: f64 = 0.0;
    for (0..@as(usize, @intCast(steps))) |_| {
        const x2 = x1 + width;
        const y2 = sample_value(function_id, x2);
        area += (y1 + y2) * width * 0.5;
        x1 = x2;
        y1 = y2;
    }
    return @intFromFloat(area * OUTPUT_SCALE + 0.5);
}
