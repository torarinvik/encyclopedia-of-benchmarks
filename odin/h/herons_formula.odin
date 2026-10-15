package herons_formula

import "core:math"

SIDE_LIMIT :: 1_000_000.0

@(export)
herons_formula :: proc "c" (a, b, c: f64) -> f64 {
    if a < 1.0 || a > SIDE_LIMIT || math.floor(a) != a ||
        b < 1.0 || b > SIDE_LIMIT || math.floor(b) != b ||
        c < 1.0 || c > SIDE_LIMIT || math.floor(c) != c ||
        a + b <= c || b + c <= a || c + a <= b do return -1.0

    s := (a + b + c) / 2.0
    return math.sqrt((s) * (s - a) * (s - b) * (s - c))
}

