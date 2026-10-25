module prolangs_c_allroots

import math

const required_bytes = 24
const newton_epsilon = 5.0e-6
const max_newton_iterations = 40

fn absolute_value(value f64) f64 {
	return if value < 0.0 { -value } else { value }
}

fn horner_value_and_derivative(coefficients []f64, x f64) (f64, f64) {
	degree := coefficients.len - 1
	mut value := coefficients[degree]
	mut slope := value
	for j := degree - 1; j >= 1; j-- {
		value = x * value + coefficients[j]
		slope = x * slope + value
	}
	value = x * value + coefficients[0]
	return value, slope
}

fn newton_root(coefficients []f64, lower_bound f64, upper_bound f64) f64 {
	mut lower := lower_bound
	mut upper := upper_bound
	if upper < lower { lower, upper = upper, lower }
	mut previous := lower
	mut current := (lower + upper) / 2.0
	mut iterations := 0
	for absolute_value(current - previous) / absolute_value(current) > newton_epsilon &&
		iterations <= max_newton_iterations {
		previous = current
		value, derivative := horner_value_and_derivative(coefficients, current)
		current -= value / derivative
		iterations++
	}
	return current
}

fn store_f64_le(mut output []u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for i in 0 .. 8 {
		output[offset + i] = u8(bits & 255)
		bits >>= 8
	}
}

fn solve(mut staged []u8) {
	original := [4.0, -4.0, -1.0, 1.0]
	coefficients := original.clone()
	mut upper := 0.0
	for coefficient in coefficients { upper += absolute_value(coefficient) }
	upper /= absolute_value(coefficients[3])
	lower := -upper - 1.0

	first_root := newton_root(coefficients, lower, upper)
	mut deflated := []f64{len: 3, init: 0.0}
	deflated[2] = coefficients[3]
	for i := 1; i >= 0; i-- { deflated[i] = deflated[i + 1] * first_root + coefficients[i + 1] }

	discriminant := deflated[1] * deflated[1] - 4.0 * deflated[2] * deflated[0]
	plus_root := (-deflated[1] + math.sqrt(discriminant)) / (2.0 * deflated[2])
	minus_root := (-deflated[1] - math.sqrt(discriminant)) / (2.0 * deflated[2])
	refined_plus := newton_root(original, plus_root - 0.5, plus_root + 0.5)
	refined_minus := newton_root(original, minus_root - 0.5, minus_root + 0.5)
	store_f64_le(mut staged, 0, first_root)
	store_f64_le(mut staged, 8, refined_plus)
	store_f64_le(mut staged, 16, refined_minus)
}

@[export: 'prolangs_c_allroots']
pub fn prolangs_c_allroots(values &i64, length usize, mut output &u8, output_capacity usize) i64 {
	unsafe {
		if values == nil || length != 4 { return -1 }
		if values[0] != 4 || values[1] != -4 || values[2] != -1 || values[3] != 1 { return -1 }
		if output == nil || output_capacity < usize(required_bytes) { return -2 }
		mut staged := []u8{len: required_bytes, init: 0}
		solve(mut staged)
		for i in 0 .. required_bytes { output[i] = staged[i] }
		return i64(required_bytes)
	}
}
