module trig_functions

import math

const pi = 3.14159265358979323846

fn rounded_six(value f64) f64 {
	magnitude := math.floor(math.abs(value) * 1_000_000.0 + 0.5) / 1_000_000.0
	return if value < 0.0 { -magnitude } else { magnitude }
}

fn integer_power(value f64, exponent int) f64 {
	mut result := 1.0
	for _ in 0 .. exponent { result *= value }
	return result
}

fn factorial_double(n int) f64 {
	mut result := 1.0
	for factor in 2 .. n + 1 { result *= f64(factor) }
	return result
}

fn trig_series(input_value f64, tolerance f64, kind int) f64 {
	mut value := input_value
	period := 2.0 * pi
	for value >= period { value -= period }
	for value <= -period { value += period }
	mut result := 0.0
	mut previous := 1.0
	mut step := 0
	for math.abs(previous - result) > tolerance {
		previous = result
		power := 2 * step + kind
		term := integer_power(value, power) / factorial_double(power)
		if step % 2 == 0 { result += term } else { result -= term }
		step++
	}
	return rounded_six(result)
}

@[export: 'trig_functions']
pub fn trig_functions(input &f64, length usize, mut output &f64, capacity usize) i64 {
	unsafe {
		if isnil(input) || length != 3 { return -1 }
		selector_value := input[0]
		mut x := input[1]
		tolerance := input[2]
		if math.is_nan(selector_value) || selector_value < 0.0 || selector_value > 7.0 || f64(int(selector_value)) != selector_value { return -1 }
		if math.is_nan(tolerance) || math.is_inf(tolerance, false) || tolerance < 1e-9 || tolerance > 1e-2 { return -1 }
		if !math.is_nan(x) && !math.is_inf(x, false) && (x < -10000.0 || x > 10000.0) { return -1 }
		if isnil(output) || capacity < 1 { return -2 }
		if math.is_nan(x) || math.is_inf(x, false) { output[0] = 0.0 / 0.0; return 1 }
		selector := int(selector_value)
		if selector == 2 || selector == 3 || selector == 6 || selector == 7 { x = x * pi / 180.0 }
		mut result := 0.0
		if selector == 0 || selector == 2 { result = trig_series(x, tolerance, 1) }
		else if selector == 1 || selector == 3 { result = trig_series(x, tolerance, 0) }
		else if selector == 4 || selector == 6 {
			denominator := trig_series(x, tolerance, 0)
			result = if denominator == 0.0 { 0.0 / 0.0 } else { trig_series(x, tolerance, 1) / denominator }
		} else {
			denominator := trig_series(x, tolerance, 1)
			result = if denominator == 0.0 { 0.0 / 0.0 } else { trig_series(x, tolerance, 0) / denominator }
		}
		output[0] = result
		return 1
	}
}
