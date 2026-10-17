const max_parseable_input_length = 45
const max_samples = 8
const max_features = 4
const max_feature_values = 32

@[export: 'linear_regression_vectorized']
pub fn linear_regression_vectorized(input &f64, length usize, mut output &f64, output_capacity usize) i64 {
	unsafe {
		if isnil(input) || length < 4 || length > max_parseable_input_length { return -1 }
		sample_value := input[0]
		feature_value := input[1]
		iteration_value := input[2]
		if sample_value != sample_value || sample_value < 2.0 || sample_value > max_samples ||
			feature_value != feature_value || feature_value < 2.0 || feature_value > max_features ||
			iteration_value != iteration_value || iteration_value < 10.0 || iteration_value > 128.0 { return -1 }
		sample_count := int(sample_value)
		feature_count := int(feature_value)
		iterations := int(iteration_value)
		if f64(sample_count) != sample_value || f64(feature_count) != feature_value ||
			f64(iterations) != iteration_value { return -1 }
		if length != usize(4 + sample_count * feature_count + sample_count) { return -1 }

		alpha := input[3]
		if alpha != alpha || alpha < 0.0001 || alpha > 0.01 { return -1 }

		mut features := [max_feature_values]f64{}
		mut labels := [max_samples]f64{}
		feature_values := sample_count * feature_count
		for index := 0; index < feature_values; index++ {
			value := input[4 + index]
			if value != value || value < -1.0 || value > 1.0 { return -1 }
			features[index] = value
		}
		for row := 0; row < sample_count; row++ {
			if features[row * feature_count] != 1.0 { return -1 }
		}
		for row := 0; row < sample_count; row++ {
			value := input[4 + feature_values + row]
			if value != value || value < -1.0 || value > 1.0 { return -1 }
			labels[row] = value
		}
		if isnil(output) || output_capacity < usize(feature_count) { return -2 }

		mut theta := [max_features]f64{}
		mut errors := [max_samples]f64{}
		mut gradients := [max_features]f64{}
		for _ in 0 .. iterations {
			for row := 0; row < sample_count; row++ {
				mut prediction := 0.0
				for column := 0; column < feature_count; column++ {
					prediction += features[row * feature_count + column] * theta[column]
				}
				errors[row] = prediction - labels[row]
			}
			for column := 0; column < feature_count; column++ {
				mut gradient := 0.0
				for row := 0; row < sample_count; row++ {
					gradient += features[row * feature_count + column] * errors[row]
				}
				gradients[column] = gradient / f64(sample_count)
			}
			for column := 0; column < feature_count; column++ { theta[column] -= alpha * gradients[column] }
		}
		for column := 0; column < feature_count; column++ { output[column] = theta[column] }
		return i64(feature_count)
	}
}
