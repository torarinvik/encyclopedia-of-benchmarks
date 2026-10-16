package logistic_regression_cost_gradient

import "core:c"
import "core:math"

MAX_SAMPLES :: 64
MAX_FEATURES :: 8
Q_SCALE :: 1_000_000.0

put_f64 :: proc "contextless" (output: [^]u8, offset: int, value: f64) {
	bits := transmute(u64)value
	for byte := 0; byte < 8; byte += 1 {
		output[offset + byte] = u8(bits >> u64(8 * byte))
	}
}

@(export)
logistic_regression_cost_gradient :: proc "c" (input: [^]i64, length: c.size_t, output: [^]u8, capacity: c.size_t) -> i64 {
	gradient: [MAX_FEATURES]f64
	total_loss := f64(0.0)
	if input == nil || length < 2 { return -1 }
	mv, dv := input[0], input[1]
	if mv < 1 || mv > MAX_SAMPLES || dv < 1 || dv > MAX_FEATURES { return -1 }
	m, d := int(mv), int(dv)
	features_offset := 2
	theta_offset := features_offset + m*d
	labels_offset := theta_offset + d
	if length != c.size_t(labels_offset+m) { return -1 }
	for index := 0; index < m*d; index += 1 {
		if input[features_offset+index] < -1_000_000 || input[features_offset+index] > 1_000_000 { return -1 }
	}
	for feature := 0; feature < d; feature += 1 {
		if input[theta_offset+feature] < -1_000_000 || input[theta_offset+feature] > 1_000_000 { return -1 }
	}
	for sample := 0; sample < m; sample += 1 {
		label := input[labels_offset+sample]
		if label != 0 && label != 1 { return -1 }
	}
	required := (d + 1) * 8
	if output == nil || capacity < c.size_t(required) { return -2 }

	for sample := 0; sample < m; sample += 1 {
		score := f64(0.0)
		for feature := 0; feature < d; feature += 1 {
			x := f64(input[features_offset+sample*d+feature]) / Q_SCALE
			theta := f64(input[theta_offset+feature]) / Q_SCALE
			score += x * theta
		}
		probability := 1.0 / (1.0 + math.exp(-score))
		label := f64(input[labels_offset+sample])
		total_loss += -label*math.ln_f64(probability) - (1.0-label)*math.ln_f64(1.0-probability)
		error := probability - label
		for feature := 0; feature < d; feature += 1 {
			x := f64(input[features_offset+sample*d+feature]) / Q_SCALE
			gradient[feature] += error * x
		}
	}
	put_f64(output, 0, total_loss/f64(m))
	for feature := 0; feature < d; feature += 1 {
		put_f64(output, (feature+1)*8, gradient[feature]/f64(m))
	}
	return i64(required)
}
