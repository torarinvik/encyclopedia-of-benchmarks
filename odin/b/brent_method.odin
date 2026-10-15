package brent_method

import "core:math"

TOLERANCE :: 1.0e-8

function_value :: proc(function_id: int, x: f64) -> f64 {
	if function_id == 0 do return x * x * x - x - 2.0
	if function_id == 1 do return x * x + 1.0
	return x * x - 4.0 * x + 3.0
}

@(export)
brent_method :: proc "c" (function_id_value, input_left, input_right: f64) -> f64 {
	if (function_id_value != 0.0 && function_id_value != 1.0 && function_id_value != 2.0) ||
		!(input_left >= -4.0 && input_left <= 4.0) || !(input_right >= -4.0 && input_right <= 4.0) || input_left >= input_right do return -1.0e300
	function_id := int(function_id_value)
	left, right := input_left, input_right
	f_left := function_value(function_id, left)
	f_right := function_value(function_id, right)
	if f_left * f_right >= 0.0 do return -1.0e300
	if math.abs(f_left) < math.abs(f_right) {
		left, right = right, left
		f_left, f_right = f_right, f_left
	}

	c := left
	f_c := f_left
	d := right - left
	for iteration := 0; iteration < 100; iteration += 1 {
		if f_right == 0.0 do return right
		candidate: f64
		if f_c != f_left && f_c != f_right {
			candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
				right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
				c * f_left * f_right / ((f_c - f_left) * (f_c - f_right))
		} else {
			candidate = right - f_right * (right - left) / (f_right - f_left)
		}

		quarter := (3.0 * left + right) / 4.0
		outside := false
		if right > left {
			outside = !(quarter < candidate && candidate < right)
		} else {
			outside = !(right < candidate && candidate < quarter)
		}
		use_bisection := outside ||
			(iteration > 1 && math.abs(candidate - right) >= math.abs(right - c) / 2.0) ||
			(iteration <= 1 && math.abs(candidate - right) >= math.abs(c - d) / 2.0) ||
			(iteration > 1 && math.abs(right - c) < TOLERANCE) ||
			(iteration <= 1 && math.abs(c - d) < TOLERANCE)
		if use_bisection {
			candidate = (left + right) / 2.0
			d = right - left
		}

		f_candidate := function_value(function_id, candidate)
		d, c = c, right
		f_c = f_right
		if f_left * f_candidate < 0.0 {
			right = candidate
			f_right = f_candidate
		} else {
			left = candidate
			f_left = f_candidate
		}
		if math.abs(f_left) < math.abs(f_right) {
			left, right = right, left
			f_left, f_right = f_right, f_left
		}
		if math.abs(right - left) < TOLERANCE do return right
	}
	return right
}
