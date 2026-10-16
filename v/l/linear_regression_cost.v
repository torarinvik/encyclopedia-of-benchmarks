module linear_regression_cost

const max_observations = 64
const max_features = 16
const max_input_length = 2 + max_observations * max_features + max_features + max_observations
const invalid_result = -1.0e300

@[export: 'linear_regression_cost']
pub fn linear_regression_cost(values &i64, length usize) f64 {
	if unsafe { values == nil } || length < 2 || length > max_input_length { return invalid_result }
	observation_value := unsafe { values[0] }
	feature_value := unsafe { values[1] }
	if observation_value < 1 || observation_value > max_observations ||
		feature_value < 1 || feature_value > max_features { return invalid_result }
	observations := int(observation_value)
	features := int(feature_value)
	matrix_length := observations * features
	if length != usize(2 + matrix_length + features + observations) { return invalid_result }
	for index := 2; index < int(length); index++ {
		value := unsafe { values[index] }
		if value < -1000 || value > 1000 { return invalid_result }
	}

	weights_start := 2 + matrix_length
	targets_start := weights_start + features
	mut squared_error_sum := f64(0)
	for row in 0 .. observations {
		mut prediction := f64(0)
		row_start := 2 + row * features
		for column in 0 .. features {
			prediction += f64(unsafe { values[row_start + column] }) * f64(unsafe { values[weights_start + column] })
		}
		residual := prediction - f64(unsafe { values[targets_start + row] })
		squared_error_sum += residual * residual
	}
	return squared_error_sum / (2 * f64(observations))
}
