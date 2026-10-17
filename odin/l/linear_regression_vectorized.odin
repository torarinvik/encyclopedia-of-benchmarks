package linear_regression_vectorized

import "core:c"

MAX_PARSEABLE_INPUT_LENGTH :: 45
MAX_SAMPLES :: 8
MAX_FEATURES :: 4
MAX_FEATURE_VALUES :: MAX_SAMPLES * MAX_FEATURES

@(export)
linear_regression_vectorized :: proc "c" (input: [^]f64, length: c.size_t,
        output: [^]f64, output_capacity: c.size_t) -> i64 {
	if input == nil || length < 4 || length > c.size_t(MAX_PARSEABLE_INPUT_LENGTH) do return -1
	sample_value, feature_value, iteration_value := input[0], input[1], input[2]
	if sample_value != sample_value || sample_value < 2.0 || sample_value > f64(MAX_SAMPLES) ||
		feature_value != feature_value || feature_value < 2.0 || feature_value > f64(MAX_FEATURES) ||
		iteration_value != iteration_value || iteration_value < 10.0 || iteration_value > 128.0 do return -1
	sample_count, feature_count, iterations := int(sample_value), int(feature_value), int(iteration_value)
	if f64(sample_count) != sample_value || f64(feature_count) != feature_value ||
		f64(iterations) != iteration_value do return -1
	if length != c.size_t(4 + sample_count * feature_count + sample_count) do return -1

	alpha := input[3]
	if alpha != alpha || alpha < 0.0001 || alpha > 0.01 do return -1

	features: [MAX_FEATURE_VALUES]f64 = {}
	labels: [MAX_SAMPLES]f64 = {}
	feature_values := sample_count * feature_count
	for index in 0..<feature_values {
		value := input[4 + index]
		if value != value || value < -1.0 || value > 1.0 do return -1
		features[index] = value
	}
	for row in 0..<sample_count {
		if features[row * feature_count] != 1.0 do return -1
	}
	for row in 0..<sample_count {
		value := input[4 + feature_values + row]
		if value != value || value < -1.0 || value > 1.0 do return -1
		labels[row] = value
	}
	if output == nil || output_capacity < c.size_t(feature_count) do return -2

	theta: [MAX_FEATURES]f64 = {}
	errors: [MAX_SAMPLES]f64 = {}
	gradients: [MAX_FEATURES]f64 = {}
	for _ in 0..<iterations {
		for row in 0..<sample_count {
			prediction: f64 = 0.0
			for column in 0..<feature_count {
				prediction += features[row * feature_count + column] * theta[column]
			}
			errors[row] = prediction - labels[row]
		}
		for column in 0..<feature_count {
			gradient: f64 = 0.0
			for row in 0..<sample_count {
				gradient += features[row * feature_count + column] * errors[row]
			}
			gradients[column] = gradient / f64(sample_count)
		}
		for column in 0..<feature_count { theta[column] -= alpha * gradients[column] }
	}
	for column in 0..<feature_count { output[column] = theta[column] }
	return i64(feature_count)
}
