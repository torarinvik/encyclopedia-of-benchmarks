module main

import math

const invalid_result = -1.0e300
const max_endpoint_micro = i64(10000000)

fn integrand(x f64) f64 {
	return math.exp(-x) * (4.0 - math.pow(x, 2.0))
}

@[export: 'simpson_integration']
pub fn simpson_integration(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 3 { return invalid_result }
	intervals := unsafe { values[0] }
	a_micro := unsafe { values[1] }
	b_micro := unsafe { values[2] }
	if intervals < 2 || intervals > 128 || intervals % 2 != 0 ||
		a_micro < -max_endpoint_micro || a_micro > max_endpoint_micro ||
		b_micro < -max_endpoint_micro || b_micro > max_endpoint_micro || a_micro > b_micro {
		return invalid_result
	}
	a := f64(a_micro) / 1000000.0
	b := f64(b_micro) / 1000000.0
	if a == b { return 0.0 }
	h := (b - a) / f64(intervals)
	mut xi := a
	mut total := 0.0
	for index in 0 .. int(intervals + 1) {
		sample := integrand(xi)
		if index == 0 || index == int(intervals) {
			total += sample
		} else if index % 2 != 0 {
			total += 4.0 * sample
		} else {
			total += 2.0 * sample
		}
		xi += h
	}
	return (h / 3.0) * total
}
