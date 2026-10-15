/// Bracket-preserving false-position root solve for f(x) = x^2 - x.
fn function_value(x: f64) -> f64 { x * x - x }

#[no_mangle]
pub extern "C" fn false_position(a_input: f64, b_input: f64) -> f64 {
    if !a_input.is_finite() || !b_input.is_finite() || a_input < 0.125 || a_input > 0.875 ||
        !((b_input >= -2.0 && b_input <= -0.125) || (b_input >= 1.125 && b_input <= 3.0)) {
        return -1.0;
    }
    let mut a = a_input;
    let mut b = b_input;
    let mut fa = function_value(a);
    let mut fb = function_value(b);
    if !(fa < 0.0 && fb > 0.0) { return -1.0; }
    let mut c = b;
    for _ in 0..256 {
        c = b - fb * (b - a) / (fb - fa);
        let fc = function_value(c);
        if fc.abs() <= 1e-12 { return c; }
        if fc < 0.0 {
            a = c;
            fa = fc;
        } else {
            b = c;
            fb = fc;
        }
    }
    if fa.abs() <= fb.abs() { a } else { b }
}
