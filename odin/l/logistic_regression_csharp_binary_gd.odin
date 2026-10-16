package logistic_regression_csharp_binary_gd

import "core:c"
import "core:math"

MAX_SAMPLES :: 32
MAX_FEATURES :: 8
Q_SCALE :: 1_000_000.0
INVALID_RESULT :: f64(-1.0e300)

@(export)
logistic_regression_csharp_binary_gd :: proc "c" (input: [^]i64, length: c.size_t) -> f64 {
	if input == nil || length < 4 do return INVALID_RESULT
	mv, dv, epochs_v, rate_q := input[0], input[1], input[2], input[3]
	if mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES ||
		epochs_v < 0 || epochs_v > 128 || rate_q < 1 || rate_q > 100_000 do return INVALID_RESULT
	m, d, epochs := int(mv), int(dv), int(epochs_v)
	labels_offset := 4 + m * d
	query_offset := labels_offset + m
	if length != c.size_t(query_offset + d) do return INVALID_RESULT
	for index := 0; index < m * d; index += 1 {
		if input[4 + index] < -1_000_000 || input[4 + index] > 1_000_000 do return INVALID_RESULT
	}
	for sample := 0; sample < m; sample += 1 {
		label := input[labels_offset + sample]
		if label != 0 && label != 1 do return INVALID_RESULT
	}
	for feature := 0; feature < d; feature += 1 {
		if input[query_offset + feature] < -1_000_000 || input[query_offset + feature] > 1_000_000 do return INVALID_RESULT
	}

	var weights: [MAX_FEATURES]f64
	var gradient: [MAX_FEATURES]f64
	bias := f64(0)
	learning_rate := f64(rate_q) / Q_SCALE
	for epoch := 0; epoch < epochs; epoch += 1 {
		for feature := 0; feature < d; feature += 1 { gradient[feature] = 0 }
		bias_gradient := f64(0)
		for sample := 0; sample < m; sample += 1 {
			dot := f64(0)
			for feature := 0; feature < d; feature += 1 {
				x := f64(input[4 + sample * d + feature]) / Q_SCALE
				dot += x * weights[feature]
			}
			linear := dot + bias
			prediction := 1.0 / (1.0 + math.exp(-linear))
			error := prediction - f64(input[labels_offset + sample])
			for feature := 0; feature < d; feature += 1 {
				x := f64(input[4 + sample * d + feature]) / Q_SCALE
				gradient[feature] += error * x
			}
			bias_gradient += error
		}
		for feature := 0; feature < d; feature += 1 {
			weights[feature] -= learning_rate * gradient[feature] / f64(m)
		}
		bias -= learning_rate * bias_gradient / f64(m)
	}
	dot := f64(0)
	for feature := 0; feature < d; feature += 1 {
		x := f64(input[query_offset + feature]) / Q_SCALE
		dot += x * weights[feature]
	}
	return 1.0 / (1.0 + math.exp(-(dot + bias)))
}
