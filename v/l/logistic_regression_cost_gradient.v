module logistic_regression_cost_gradient

import math

const max_samples = 64
const max_features = 8
const q_scale = 1000000.0

fn put_f64(mut output &u8, offset int, value f64) {
	mut bits := math.f64_bits(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'logistic_regression_cost_gradient']
pub fn logistic_regression_cost_gradient(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 2 { return -1 }
	unsafe {
		m_value, d_value := input[0], input[1]
		if m_value < 1 || m_value > max_samples || d_value < 1 || d_value > max_features { return -1 }
		m, d := int(m_value), int(d_value)
		features_offset := 2
		theta_offset := features_offset + m * d
		labels_offset := theta_offset + d
		if length != usize(labels_offset + m) { return -1 }
		for index in 0 .. m * d {
			if input[features_offset + index] < -1000000 || input[features_offset + index] > 1000000 { return -1 }
		}
		for feature in 0 .. d {
			if input[theta_offset + feature] < -1000000 || input[theta_offset + feature] > 1000000 { return -1 }
		}
		for sample in 0 .. m {
			label := input[labels_offset + sample]
			if label != 0 && label != 1 { return -1 }
		}
		required := (d + 1) * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }

		mut loss := 0.0
		mut gradient := [max_features]f64{}
		for sample in 0 .. m {
			mut score := 0.0
			for feature in 0 .. d {
				x := f64(input[features_offset + sample * d + feature]) / q_scale
				theta := f64(input[theta_offset + feature]) / q_scale
				score += x * theta
			}
			probability := 1.0 / (1.0 + math.exp(-score))
			label := f64(input[labels_offset + sample])
			loss += -label * math.log(probability) - (1.0 - label) * math.log(1.0 - probability)
			error := probability - label
			for feature in 0 .. d {
				x := f64(input[features_offset + sample * d + feature]) / q_scale
				gradient[feature] += error * x
			}
		}
		put_f64(mut output, 0, loss / f64(m))
		for feature in 0 .. d {
			put_f64(mut output, (feature + 1) * 8, gradient[feature] / f64(m))
		}
		return i64(required)
	}
}
