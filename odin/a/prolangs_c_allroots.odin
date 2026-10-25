package prolangs_c_allroots

import "core:c"
import "core:math"

REQUIRED_BYTES :: 24
NEWTON_EPSILON :: 5.0e-6
MAX_NEWTON_ITERATIONS :: 40

absolute_value :: proc "contextless" (value: f64) -> f64 {
	if value < 0.0 do return -value
	return value
}

horner_value_and_derivative :: proc "contextless" (coefficients: [^]f64, degree: int, x: f64) -> (f64, f64) {
	value := coefficients[degree]
	slope := value
	for j := degree-1; j >= 1; j -= 1 {
		value = x*value + coefficients[j]
		slope = x*slope + value
	}
	value = x*value + coefficients[0]
	return value, slope
}

newton_root :: proc "contextless" (coefficients: [^]f64, degree: int, lower_bound, upper_bound: f64) -> f64 {
	lower := lower_bound
	upper := upper_bound
	if upper < lower { lower, upper = upper, lower }
	previous := lower
	current := (lower+upper)/2.0
	iterations := 0
	for absolute_value(current-previous)/absolute_value(current) > NEWTON_EPSILON && iterations <= MAX_NEWTON_ITERATIONS {
		previous = current
		value, derivative := horner_value_and_derivative(coefficients, degree, current)
		current -= value/derivative
		iterations += 1
	}
	return current
}

store_f64_le :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for i := 0; i < 8; i += 1 { output[offset+i] = u8(bits >> u64(8*i)) }
}

solve :: proc "contextless" (output: [^]u8) {
	original := [4]f64{4.0, -4.0, -1.0, 1.0}
	coefficients := original
	upper := 0.0
	for i := 0; i <= 3; i += 1 { upper += absolute_value(coefficients[i]) }
	upper /= absolute_value(coefficients[3])
	lower := -upper-1.0

	first_root := newton_root(&coefficients[0], 3, lower, upper)
	deflated: [3]f64
	deflated[2] = coefficients[3]
	for i := 1; i >= 0; i -= 1 { deflated[i] = deflated[i+1]*first_root+coefficients[i+1] }

	discriminant := deflated[1]*deflated[1]-4.0*deflated[2]*deflated[0]
	plus_root := (-deflated[1]+math.sqrt(discriminant))/(2.0*deflated[2])
	minus_root := (-deflated[1]-math.sqrt(discriminant))/(2.0*deflated[2])
	refined_plus := newton_root(&original[0], 3, plus_root-0.5, plus_root+0.5)
	refined_minus := newton_root(&original[0], 3, minus_root-0.5, minus_root+0.5)
	store_f64_le(output, 0, first_root)
	store_f64_le(output, 8, refined_plus)
	store_f64_le(output, 16, refined_minus)
}

@(export)
prolangs_c_allroots :: proc "c" (values: [^]i64, length: c.size_t,
	output: [^]u8, capacity: c.size_t) -> i64 {
	if values == nil || length != 4 do return -1
	if values[0] != 4 || values[1] != -4 || values[2] != -1 || values[3] != 1 do return -1
	if output == nil || capacity < REQUIRED_BYTES do return -2
	staged: [REQUIRED_BYTES]u8
	solve(&staged[0])
	for i := 0; i < REQUIRED_BYTES; i += 1 { output[i] = staged[i] }
	return REQUIRED_BYTES
}
