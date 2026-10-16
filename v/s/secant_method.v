module main

import math

const invalid_result = -1.0e300

fn python_objective(x f64) f64 {
	return 8.0 * x - 2.0 * math.exp(-x)
}

fn c_variant() f64 {
	mut x0 := 0.2
	mut x1 := 0.5
	tolerance := 100.0 / 1000000.0
	for _ in 0 .. 99 {
		f1 := x1 * x1 - 3.0
		f0 := x0 * x0 - 3.0
		x2 := x1 - f1 * (x1 - x0) / (f1 - f0)
		x0 = x1
		x1 = x2
		if math.abs(x1 - x0) < tolerance {
			return x2
		}
	}
	return -1.0
}

fn python_variant(repeats i64) f64 {
	mut x0 := 1.0
	mut x1 := 3.0
	for _ in i64(0) .. repeats {
		f1 := python_objective(x1)
		f0 := python_objective(x0)
		x2 := x1 - (f1 * (x1 - x0)) / (f1 - f0)
		x0 = x1
		x1 = x2
	}
	return x1
}

@[export: 'secant_method']
pub fn secant_method(values &i64, length usize) f64 {
	if unsafe { values == nil } || length != 2 {
		return invalid_result
	}
	variant := unsafe { values[0] }
	control := unsafe { values[1] }
	if variant == 0 && control == 100 {
		return c_variant()
	}
	if variant == 1 && control >= 0 && control <= 2 {
		return python_variant(control)
	}
	return invalid_result
}
