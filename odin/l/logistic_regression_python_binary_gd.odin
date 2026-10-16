package logistic_regression_python_binary_gd

import "core:c"
import "core:math"

MAX_SAMPLES :: 32
MAX_FEATURES :: 8
Q_SCALE :: 1_000_000.0

put_f64 :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> (8 * byte))
	}
}

@(export)
logistic_regression_python_binary_gd :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	if input == nil || length < 4 do return -1
	mv, dv, epochs_v, alpha_q := input[0], input[1], input[2], input[3]
	if mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES ||
		epochs_v < 0 || epochs_v > 128 || alpha_q < 1 || alpha_q > 100000 do return -1
	m, d, epochs := int(mv), int(dv), int(epochs_v)
	if length != c.size_t(4 + m * d + m) do return -1
	labels_offset := 4 + m * d
	for index := 0; index < m * d; index += 1 {
		if input[4 + index] < -1_000_000 || input[4 + index] > 1_000_000 do return -1
	}
	for sample := 0; sample < m; sample += 1 {
		label := input[labels_offset + sample]
		if label != 0 && label != 1 do return -1
	}
	required := d * 8
	if output == nil || capacity < c.size_t(required) do return -2

	var theta: [MAX_FEATURES]f64
	var next_theta: [MAX_FEATURES]f64
	var errors: [MAX_SAMPLES]f64
	alpha := f64(alpha_q) / Q_SCALE
	for epoch := 0; epoch < epochs; epoch += 1 {
		for sample := 0; sample < m; sample += 1 {
			score := 0.0
			for feature := 0; feature < d; feature += 1 {
				x := f64(input[4 + sample * d + feature]) / Q_SCALE
				score += x * theta[feature]
			}
			prediction := 1.0 / (1.0 + math.exp(-score))
			errors[sample] = prediction - f64(input[labels_offset + sample])
		}
		for feature := 0; feature < d; feature += 1 {
			gradient := 0.0
			for sample := 0; sample < m; sample += 1 {
				x := f64(input[4 + sample * d + feature]) / Q_SCALE
				gradient += x * errors[sample]
			}
			gradient /= f64(m)
			next_theta[feature] = theta[feature] - alpha * gradient
		}
		for feature := 0; feature < d; feature += 1 {
			theta[feature] = next_theta[feature]
		}
	}
	for feature := 0; feature < d; feature += 1 {
		put_f64(output, feature * 8, theta[feature])
	}
	return i64(required)
}
