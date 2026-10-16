module logistic_regression_csharp_binary_gd

import core:c
import math

const max_samples = 32
const max_features = 8
const q_scale = 1_000_000.0
const invalid_result = -1.0e300

@[export: 'logistic_regression_csharp_binary_gd']
pub fn logistic_regression_csharp_binary_gd(input &i64, length usize) f64 {
	if unsafe { input == nil } || length < 4 { return invalid_result }
	unsafe {
		mv, dv, epochs_v, rate_q := input[0], input[1], input[2], input[3]
		if mv < 1 || mv > max_samples || dv < 1 || dv > max_features ||
			epochs_v < 0 || epochs_v > 128 || rate_q < 1 || rate_q > 100000 { return invalid_result }
		m, d, epochs := int(mv), int(dv), int(epochs_v)
		labels_offset := 4 + m * d
		query_offset := labels_offset + m
		if length != usize(query_offset + d) { return invalid_result }
		for index in 0 .. m * d {
			if input[4 + index] < -1000000 || input[4 + index] > 1000000 { return invalid_result }
		}
		for sample in 0 .. m {
			label := input[labels_offset + sample]
			if label != 0 && label != 1 { return invalid_result }
		}
		for feature in 0 .. d {
			if input[query_offset + feature] < -1000000 || input[query_offset + feature] > 1000000 { return invalid_result }
		}
		mut weights := [max_features]f64{}
		mut gradient := [max_features]f64{}
		mut bias := 0.0
		learning_rate := f64(rate_q) / q_scale
		for _ in 0 .. epochs {
			for feature in 0 .. d { gradient[feature] = 0.0 }
			mut bias_gradient := 0.0
			for sample in 0 .. m {
				mut dot := 0.0
				for feature in 0 .. d {
					x := f64(input[4 + sample * d + feature]) / q_scale
					dot += x * weights[feature]
				}
				linear := dot + bias
				prediction := 1.0 / (1.0 + math.exp(-linear))
				error := prediction - f64(input[labels_offset + sample])
				for feature in 0 .. d {
					x := f64(input[4 + sample * d + feature]) / q_scale
					gradient[feature] += error * x
				}
				bias_gradient += error
			}
			for feature in 0 .. d { weights[feature] -= learning_rate * gradient[feature] / f64(m) }
			bias -= learning_rate * bias_gradient / f64(m)
		}
		mut query_dot := 0.0
		for feature in 0 .. d {
			x := f64(input[query_offset + feature]) / q_scale
			query_dot += x * weights[feature]
		}
		query_linear := query_dot + bias
		return 1.0 / (1.0 + math.exp(-query_linear))
	}
}
