package linear_regression_cost

import "core:c"

MAX_OBSERVATIONS :: 64
MAX_FEATURES :: 16
MAX_INPUT_LENGTH :: 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS
INVALID_RESULT :: -1.0e300

@(export)
linear_regression_cost :: proc "c" (values: [^]i64, length: c.size_t) -> f64 {
    if values == nil || length < 2 || length > c.size_t(MAX_INPUT_LENGTH) do return INVALID_RESULT
    observation_value := values[0]
    feature_value := values[1]
    if observation_value < 1 || observation_value > MAX_OBSERVATIONS do return INVALID_RESULT
    if feature_value < 1 || feature_value > MAX_FEATURES do return INVALID_RESULT
    observations := int(observation_value)
    features := int(feature_value)
    matrix_length := observations * features
    if int(length) != 2 + matrix_length + features + observations do return INVALID_RESULT
    for index := 2; index < int(length); index += 1 {
        if values[index] < -1000 || values[index] > 1000 do return INVALID_RESULT
    }

    weights_start := 2 + matrix_length
    targets_start := weights_start + features
    squared_error_sum: f64 = 0
    for row := 0; row < observations; row += 1 {
        prediction: f64 = 0
        row_start := 2 + row * features
        for column := 0; column < features; column += 1 {
            prediction += f64(values[row_start + column]) * f64(values[weights_start + column])
        }
        error := prediction - f64(values[targets_start + row])
        squared_error_sum += error * error
    }
    return squared_error_sum / (2 * f64(observations))
}
