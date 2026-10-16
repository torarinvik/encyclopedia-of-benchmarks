module logistic_regression_python_binary_gd

import core:c
import math

const max_samples = 32
const max_features = 8
const q_scale = 1_000_000.0

fn put_f64(mut output &u8, offset int, value f64) {
	mut bits := math.bits_from_f64(value)
	for byte in 0 .. 8 {
		unsafe { output[offset + byte] = u8(bits & 255) }
		bits >>= 8
	}
}

@[export: 'logistic_regression_python_binary_gd']
pub fn logistic_regression_python_binary_gd(input &i64, length usize, mut output &u8, capacity usize) i64 {
	if unsafe { input == nil } || length < 4 { return -1 }
	unsafe {
		mv, dv, epochs_v, alpha_q := input[0], input[1], input[2], input[3]
		if mv < 1 || mv > max_samples || dv < 1 || dv > max_features ||
			epochs_v < 0 || epochs_v > 128 || alpha_q < 1 || alpha_q > 100000 { return -1 }
		m, d, epochs := int(mv), int(dv), int(epochs_v)
		if length != usize(4 + m * d + m) { return -1 }
		labels_offset := 4 + m * d
		for index in 0 .. m * d {
			if input[4 + index] < -1000000 || input[4 + index] > 1000000 { return -1 }
		}
		for sample in 0 .. m {
			label := input[labels_offset + sample]
			if label != 0 && label != 1 { return -1 }
		}
		required := d * 8
		if capacity < required || (required != 0 && output == nil) { return -2 }
		mut theta := [max_features]f64{}
		mut next_theta := [max_features]f64{}
		mut errors := [max_samples]f64{}
		alpha := f64(alpha_q) / q_scale
		for _ in 0 .. epochs {
			for sample in 0 .. m {
				mut score := 0.0
				for feature in 0 .. d {
					x := f64(input[4 + sample * d + feature]) / q_scale
					score += x * theta[feature]
				}
				prediction := 1.0 / (1.0 + math.exp(-score))
				errors[sample] = prediction - f64(input[labels_offset + sample])
			}
			for feature in 0 .. d {
				mut gradient := 0.0
				for sample in 0 .. m {
					x := f64(input[4 + sample * d + feature]) / q_scale
					gradient += x * errors[sample]
				}
				gradient /= f64(m)
				next_theta[feature] = theta[feature] - alpha * gradient
			}
			for feature in 0 .. d { theta[feature] = next_theta[feature] }
		}
		for feature in 0 .. d { put_f64(mut output, feature * 8, theta[feature]) }
		return i64(required)
	}
}
