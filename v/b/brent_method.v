module brent_method

import math

const tolerance = 1.0e-8

fn function_value(function_id int, x f64) f64 {
	if function_id == 0 { return x * x * x - x - 2.0 }
	if function_id == 1 { return x * x + 1.0 }
	return x * x - 4.0 * x + 3.0
}

@[export: 'brent_method']
pub fn brent_method(function_id_value f64, input_left f64, input_right f64) f64 {
	if (function_id_value != 0.0 && function_id_value != 1.0 && function_id_value != 2.0) ||
		!(input_left >= -4.0 && input_left <= 4.0) || !(input_right >= -4.0 && input_right <= 4.0) || input_left >= input_right {
		return -1.0e300
	}
	function_id := int(function_id_value)
	mut left := input_left
	mut right := input_right
	mut f_left := function_value(function_id, left)
	mut f_right := function_value(function_id, right)
	if f_left * f_right >= 0.0 { return -1.0e300 }
	if math.abs(f_left) < math.abs(f_right) {
		temporary := left
		left = right
		right = temporary
		temporary_f := f_left
		f_left = f_right
		f_right = temporary_f
	}

	mut c := left
	mut f_c := f_left
	mut d := right - left
	for mut iteration := 0; iteration < 100; iteration++ {
		if f_right == 0.0 { return right }
		mut candidate := f64(0.0)
		if f_c != f_left && f_c != f_right {
			candidate = left * f_right * f_c / ((f_left - f_right) * (f_left - f_c)) +
				right * f_left * f_c / ((f_right - f_left) * (f_right - f_c)) +
				c * f_left * f_right / ((f_c - f_left) * (f_c - f_right))
		} else {
			candidate = right - f_right * (right - left) / (f_right - f_left)
		}

		quarter := (3.0 * left + right) / 4.0
		outside := if right > left { !(quarter < candidate && candidate < right) } else { !(right < candidate && candidate < quarter) }
		use_bisection := outside ||
			(iteration > 1 && math.abs(candidate - right) >= math.abs(right - c) / 2.0) ||
			(iteration <= 1 && math.abs(candidate - right) >= math.abs(c - d) / 2.0) ||
			(iteration > 1 && math.abs(right - c) < tolerance) ||
			(iteration <= 1 && math.abs(c - d) < tolerance)
		if use_bisection {
			candidate = (left + right) / 2.0
			d = right - left
		}

		f_candidate := function_value(function_id, candidate)
		d = c
		c = right
		f_c = f_right
		if f_left * f_candidate < 0.0 {
			right = candidate
			f_right = f_candidate
		} else {
			left = candidate
			f_left = f_candidate
		}
		if math.abs(f_left) < math.abs(f_right) {
			temporary := left
			left = right
			right = temporary
			temporary_f := f_left
			f_left = f_right
			f_right = temporary_f
		}
		if math.abs(right - left) < tolerance { return right }
	}
	return right
}
