module herons_formula

import math

const side_limit = 1_000_000.0

@[export: 'herons_formula']
pub fn herons_formula(a f64, b f64, c f64) f64 {
    if a < 1.0 || a > side_limit || math.floor(a) != a ||
        b < 1.0 || b > side_limit || math.floor(b) != b ||
        c < 1.0 || c > side_limit || math.floor(c) != c ||
        a + b <= c || b + c <= a || c + a <= b {
        return -1.0
    }

    s := (a + b + c) / 2.0
    return math.sqrt((s) * (s - a) * (s - b) * (s - c))
}

