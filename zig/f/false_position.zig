/// Bracket-preserving false-position root solve for f(x) = x^2 - x.
const std = @import("std");

fn functionValue(x: f64) f64 { return x * x - x; }

export fn false_position(a_input: f64, b_input: f64) f64 {
    if (!std.math.isFinite(a_input) or !std.math.isFinite(b_input) or
        a_input < 0.125 or a_input > 0.875 or
        !((b_input >= -2.0 and b_input <= -0.125) or (b_input >= 1.125 and b_input <= 3.0))) return -1.0;
    var a = a_input;
    var b = b_input;
    var fa = functionValue(a);
    var fb = functionValue(b);
    if (!(fa < 0.0 and fb > 0.0)) return -1.0;
    var c = b;
    for (0..256) |_| {
        c = b - fb * (b - a) / (fb - fa);
        const fc = functionValue(c);
        if (@abs(fc) <= 1e-12) return c;
        if (fc < 0.0) {
            a = c;
            fa = fc;
        } else {
            b = c;
            fb = fc;
        }
    }
    return if (@abs(fa) <= @abs(fb)) a else b;
}
