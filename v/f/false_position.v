module false_position

import math

fn function_value(x f64) f64 { return x * x - x }

@[export: 'false_position']
pub fn false_position(a_input f64, b_input f64) f64 {
    if a_input != a_input || b_input != b_input || a_input < 0.125 || a_input > 0.875 ||
        !((b_input >= -2.0 && b_input <= -0.125) || (b_input >= 1.125 && b_input <= 3.0)) {
        return -1.0
    }
    mut a := a_input
    mut b := b_input
    mut fa := function_value(a)
    mut fb := function_value(b)
    if !(fa < 0.0 && fb > 0.0) { return -1.0 }
    mut c := b
    for _ in 0 .. 256 {
        c = b - fb * (b - a) / (fb - fa)
        fc := function_value(c)
        if math.abs(fc) <= 1e-12 { return c }
        if fc < 0.0 {
            a = c
            fa = fc
        } else {
            b = c
            fb = fc
        }
    }
    if math.abs(fa) <= math.abs(fb) { return a }
    return b
}
