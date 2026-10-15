/// Find a root of one of two documented cubics by interval bisection.
const MAX_COORD_MILLI: i64 = 100000;
const MAX_TOLERANCE_MICRO: i64 = 1000000;
const ROOT_SCALE: f64 = 1000000.0;
const MAX_ITERATIONS: usize = 64;

fn evaluate(equation: i64, x: f64) f64 {
    return if (equation == 0) x * x * x + 2.0 * x - 10.0 else x * x * x - 4.0 * x - 9.0;
}

export fn bisection_method(input: [*]const i64, length: usize) i64 {
    if (length != 4) return -1;
    const equation = input[0];
    const left_milli = input[1];
    const right_milli = input[2];
    const tolerance_micro = input[3];
    if (equation < 0 or equation > 1 or left_milli < -MAX_COORD_MILLI or left_milli > MAX_COORD_MILLI or
        right_milli < -MAX_COORD_MILLI or right_milli > MAX_COORD_MILLI or left_milli >= right_milli or
        tolerance_micro < 1 or tolerance_micro > MAX_TOLERANCE_MICRO) return -1;
    var left = @as(f64, @floatFromInt(left_milli)) / 1000.0;
    var right = @as(f64, @floatFromInt(right_milli)) / 1000.0;
    var f_left = evaluate(equation, left);
    const f_right = evaluate(equation, right);
    if (f_left == 0.0) return @intFromFloat(left * ROOT_SCALE + 0.5);
    if (f_right == 0.0) return @intFromFloat(right * ROOT_SCALE + 0.5);
    if ((f_left < 0.0) == (f_right < 0.0)) return -2;
    const tolerance = @as(f64, @floatFromInt(tolerance_micro)) / ROOT_SCALE;
    for (0..MAX_ITERATIONS) |_| {
        const middle = left + (right - left) * 0.5;
        const f_middle = evaluate(equation, middle);
        if (f_middle == 0.0) return @intFromFloat(middle * ROOT_SCALE + 0.5);
        if ((f_left < 0.0) != (f_middle < 0.0)) {
            right = middle;
        } else {
            left = middle;
            f_left = f_middle;
        }
        if (right - left <= tolerance)
            return @intFromFloat((left + (right - left) * 0.5) * ROOT_SCALE + 0.5);
    }
    return -2;
}
