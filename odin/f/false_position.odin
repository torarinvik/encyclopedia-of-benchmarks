package false_position

import "core:math"

function_value :: proc "contextless" (x: f64) -> f64 { return x * x - x }

@(export)
false_position :: proc "c" (a_input, b_input: f64) -> f64 {
    if math.is_nan(a_input) || math.is_nan(b_input) || a_input < 0.125 || a_input > 0.875 ||
            !((b_input >= -2.0 && b_input <= -0.125) || (b_input >= 1.125 && b_input <= 3.0)) {
        return -1.0
    }
    a := a_input
    b := b_input
    fa := function_value(a)
    fb := function_value(b)
    if !(fa < 0.0 && fb > 0.0) do return -1.0
    c := b
    for iteration := 0; iteration < 256; iteration += 1 {
        c = b - fb * (b - a) / (fb - fa)
        fc := function_value(c)
        if math.abs(fc) <= 1e-12 do return c
        if fc < 0.0 {
            a = c
            fa = fc
        } else {
            b = c
            fb = fc
        }
    }
    if math.abs(fa) <= math.abs(fb) do return a
    return b
}
