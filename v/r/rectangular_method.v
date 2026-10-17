module main

import math

const invalid_result = -1.0e300

fn integrand(x f64) f64 {
	return (math.exp(x) / 2.0) * (math.cos(x) - math.sin(x))
}

@[export: 'rectangular_method']
pub fn rectangular_method(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 4 { return invalid_result }
	a_quarters := unsafe { values[0] }
	b_quarters := unsafe { values[1] }
	intervals := unsafe { values[2] }
	rule := unsafe { values[3] }
	if a_quarters < -64 || a_quarters >= b_quarters || b_quarters > 64 ||
		intervals < 1 || intervals > 64 { return invalid_result }
	if (b_quarters - a_quarters) % intervals != 0 || (rule != 0 && rule != 1) {
		return invalid_result
	}

	a := f64(a_quarters) / 4.0
	b := f64(b_quarters) / 4.0
	step := (b - a) / f64(intervals)
	mut x := a
	mut total := 0.0
	for _ in 0 .. int(intervals) {
		if rule == 0 {
			total += integrand(x) * step
			x += step
		} else {
			x += step
			total += integrand(x) * step
		}
	}
	return total
}
