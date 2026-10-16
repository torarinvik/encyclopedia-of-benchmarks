const INVALID_RESULT: f64 = -1.0e300;
const PI: f64 = 3.14159265358979323846264338327950288;

fn factorial(n: i64) f64 { var result: f64 = 1.0; var i: i64 = 2; while (i <= n) : (i += 1) result *= @floatFromInt(i); return result; }

export fn maclaurin_series(values: [*]const i64, length: usize) f64 {
    if (length != 3) return INVALID_RESULT;
    const mode, theta_input, accuracy = .{ values[0], values[1], values[2] };
    if ((mode != 0 and mode != 1) or theta_input < -10 or theta_input > 10 or accuracy < 1 or accuracy > 30) return INVALID_RESULT;
    var theta: f64 = @floatFromInt(theta_input);
    const div = @floor(theta / (2.0 * PI));
    theta = theta - 2.0 * div * PI;
    var sum: f64 = 0.0;
    var r: i64 = 0;
    while (r < accuracy) : (r += 1) {
        const exponent: i64 = if (mode == 0) 2 * r + 1 else 2 * r;
        const sign: f64 = if (@mod(r, 2) == 0) 1.0 else -1.0;
        sum += sign * std.math.pow(f64, theta, @floatFromInt(exponent)) / factorial(exponent);
    }
    return sum;
}
