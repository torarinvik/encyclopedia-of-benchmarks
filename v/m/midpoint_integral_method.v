module main

import math

const invalid_result = -1.0e300

fn integrand(function_id i64, x f64) f64 {
    match function_id {
        0 { return math.sqrt(x) + math.log(x) }
        1 { return math.exp(-x) * (4.0 - math.pow(x, 2.0)) }
        2 { return math.sqrt(2.0 * math.pow(x, 3.0) + 3.0) }
        3 { return x + math.log(2.0 * x + 1.0) }
        else { return invalid_result }
    }
}

@[export: 'midpoint_integral_method']
pub fn midpoint_integral_method(values &i64, length usize) f64 {
    if unsafe { values == nil } || length != 4 { return invalid_result }
    function_id := unsafe { values[0] }
    intervals := unsafe { values[1] }
    a_milli := unsafe { values[2] }
    b_milli := unsafe { values[3] }
    if function_id < 0 || function_id > 3 || intervals < 2 || intervals > 64 || intervals % 2 != 0 ||
        a_milli < 0 || a_milli >= b_milli || b_milli > 10000 { return invalid_result }
    a := f64(a_milli) / 1000.0
    b := f64(b_milli) / 1000.0
    h := (b - a) / f64(intervals)
    mut xi := a
    mut total := 0.0
    for _ in 0 .. int(intervals) {
        total += integrand(function_id, xi + h / 2.0)
        xi += h
    }
    return total * h
}
