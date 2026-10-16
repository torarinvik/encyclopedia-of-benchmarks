package in_static_equilibrium

import "core:c"

INVALID_RESULT :: i64(-1)

@(export)
in_static_equilibrium :: proc "c" (values: [^]i64, length: c.size_t) -> i64 {
    if values == nil || length < 5 do return INVALID_RESULT
    n_value := values[0]
    if n_value < 1 || n_value > 100 || length != 1 + 4*c.size_t(n_value) do return INVALID_RESULT
    n := int(n_value)
    total_moment: i64 = 0
    for i in 0..<n {
        fx, fy := values[1+i], values[1+n+i]
        lx, ly := values[1+2*n+i], values[1+3*n+i]
        if fx < -1000 || fx > 1000 || fy < -1000 || fy > 1000 || lx < -1000 || lx > 1000 || ly < -1000 || ly > 1000 do return INVALID_RESULT
        total_moment += lx*fy - ly*fx
    }
    return if total_moment == 0 do 1 else 0
}
