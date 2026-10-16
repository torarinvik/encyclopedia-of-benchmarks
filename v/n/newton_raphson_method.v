module main

import math

const invalid_result = -1.0e300

fn equation(x f64) f64 { return math.pow(x, 3.0) - (4.0 * x) - 9.0 }
fn derivative(x f64) f64 { return 3.0 * math.pow(x, 2.0) - 4.0 }

@[export: 'newton_raphson_method']
pub fn newton_raphson_method(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 2 { return invalid_result }
    initial_milli := unsafe { values[0] }
    iteration_limit := unsafe { values[1] }
    if initial_milli < 2000 || initial_milli > 4000 || iteration_limit < 1 || iteration_limit > 32 { return invalid_result }
    mut c := f64(initial_milli) / 1000.0
    mut z := c
    for _ in 0 .. int(iteration_limit) {
        m := equation(c)
        n := derivative(c)
        z = c - (m / n)
        c = z
        if math.abs(m) < 1e-10 { break }
    }
    return z
}
