module soboleva_modified_hyperbolic_tangent

import math

const max_sample_count = 32
const max_parseable_input_length = 38

@[export: 'soboleva_modified_hyperbolic_tangent']
pub fn soboleva_modified_hyperbolic_tangent(input &f64, input_length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if input == nil || input_length < 5 || input_length > usize(max_parseable_input_length) { return -1 }
		count_value := input[0]
		if count_value != count_value || count_value < 1.0 || count_value > f64(max_sample_count) { return -1 }
		count := int(count_value)
		if count_value != f64(count) || input_length != usize(5 + count) { return -1 }

		a, b, c, d := input[1], input[2], input[3], input[4]
		for coefficient in [a, b, c, d] {
			if coefficient != coefficient || coefficient < -2.0 || coefficient > 2.0 { return -1 }
		}
		for index in 0 .. count {
			x := input[index + 5]
			if x != x || x < -20.0 || x > 20.0 { return -1 }
		}
		if output == nil || output_capacity < usize(count) { return -2 }

		for index in 0 .. count {
			x := input[index + 5]
			exp_ax := math.exp(a * x)
			exp_neg_bx := math.exp((-b) * x)
			numerator := exp_ax - exp_neg_bx
			exp_cx := math.exp(c * x)
			exp_neg_dx := math.exp((-d) * x)
			denominator := exp_cx + exp_neg_dx
			output[index] = numerator / denominator
		}
		return i64(count)
	}
}
