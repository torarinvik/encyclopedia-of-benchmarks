package soboleva_modified_hyperbolic_tangent

import "core:c"
import "core:math"

MAX_SAMPLE_COUNT :: 32
MAX_PARSEABLE_INPUT_LENGTH :: c.size_t(38)

soboleva_modified_hyperbolic_tangent :: proc "c" (input: [^]f64, input_length: c.size_t,
	output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH do return -1
	count_value := input[0]
	if count_value != count_value || count_value < 1.0 || count_value > MAX_SAMPLE_COUNT do return -1
	count := int(count_value)
	if count_value != f64(count) || input_length != c.size_t(5+count) do return -1

	a, b, c_value, d := input[1], input[2], input[3], input[4]
	if a != a || b != b || c_value != c_value || d != d ||
		a < -2.0 || a > 2.0 || b < -2.0 || b > 2.0 ||
		c_value < -2.0 || c_value > 2.0 || d < -2.0 || d > 2.0 do return -1
	for index in 0..<count {
		x := input[index+5]
		if x != x || x < -20.0 || x > 20.0 do return -1
	}
	if output == nil || output_capacity < c.size_t(count) do return -2

	for index in 0..<count {
		x := input[index+5]
		exp_ax := math.exp(a*x)
		exp_neg_bx := math.exp((-b)*x)
		numerator := exp_ax-exp_neg_bx
		exp_cx := math.exp(c_value*x)
		exp_neg_dx := math.exp((-d)*x)
		denominator := exp_cx+exp_neg_dx
		output[index] = numerator/denominator
	}
	return i64(count)
}
