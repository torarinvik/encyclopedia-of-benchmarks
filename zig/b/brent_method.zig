const TOLERANCE: f64 = 1.0e-8;

fn functionValue(function_id: i32, x: f64) f64 {
    if (function_id == 0) return x * x * x - x - 2.0;
    if (function_id == 1) return x * x + 1.0;
    return x * x - 4.0 * x + 3.0;
}

export fn brent_method(function_id_value: f64, input_left: f64, input_right: f64) f64 {
    if ((function_id_value != 0.0 and function_id_value != 1.0 and function_id_value != 2.0) or
        !(input_left >= -4.0 and input_left <= 4.0) or !(input_right >= -4.0 and input_right <= 4.0) or input_left >= input_right)
        return -1.0e300;
    const function_id: i32 = @intFromFloat(function_id_value);
    var left = input_left;
    var right = input_right;
    var f_left = functionValue(function_id, left);
    var f_right = functionValue(function_id, right);
    if (f_left * f_right >= 0.0) return -1.0e300;
    if (@abs(f_left) < @abs(f_right)) {
        const old_left = left;
        left = right;
        right = old_left;
        const old_f_left = f_left;
        f_left = f_right;
        f_right = old_f_left;
    }

    var c = left;
    var f_c = f_left;
    var d = right - left;
    for (0..100) |iteration| {
        if (f_right == 0.0) return right;
        var candidate: f64 = undefined;
        if (f_c != f_left and f_c != f_right) {
            candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
                right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
                c * f_left * f_right / ((f_c - f_left) * (f_c - f_right));
        } else {
            candidate = right - f_right * (right - left) / (f_right - f_left);
        }

        const quarter = (3.0 * left + right) / 4.0;
        const outside = if (right > left) !(quarter < candidate and candidate < right)
                        else !(right < candidate and candidate < quarter);
        const iteration_i = @as(i64, @intCast(iteration));
        const use_bisection = outside or
            (iteration_i > 1 and @abs(candidate - right) >= @abs(right - c) / 2.0) or
            (iteration_i <= 1 and @abs(candidate - right) >= @abs(c - d) / 2.0) or
            (iteration_i > 1 and @abs(right - c) < TOLERANCE) or
            (iteration_i <= 1 and @abs(c - d) < TOLERANCE);
        if (use_bisection) {
            candidate = (left + right) / 2.0;
            d = right - left;
        }

        const f_candidate = functionValue(function_id, candidate);
        d = c;
        c = right;
        f_c = f_right;
        if (f_left * f_candidate < 0.0) {
            right = candidate;
            f_right = f_candidate;
        } else {
            left = candidate;
            f_left = f_candidate;
        }
        if (@abs(f_left) < @abs(f_right)) {
            const old_left = left;
            left = right;
            right = old_left;
            const old_f_left = f_left;
            f_left = f_right;
            f_right = old_f_left;
        }
        if (@abs(right - left) < TOLERANCE) return right;
    }
    return right;
}
