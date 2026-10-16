module linear_regression_cost;

const usz MAX_OBSERVATIONS = 64;
const usz MAX_FEATURES = 16;
const usz MAX_INPUT_LENGTH = 2 + MAX_OBSERVATIONS * MAX_FEATURES + MAX_FEATURES + MAX_OBSERVATIONS;
const double INVALID_RESULT = -1.0e300;

fn double linear_regression_cost(long* values, usz length) @export("linear_regression_cost") {
    if (values == null || length < 2 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    if (values[0] < 1 || values[0] > 64 || values[1] < 1 || values[1] > 16) return INVALID_RESULT;
    usz observations = (usz)values[0];
    usz features = (usz)values[1];
    usz matrix_length = observations * features;
    if (length != 2 + matrix_length + features + observations) return INVALID_RESULT;
    for (usz index = 2; index < length; index++) {
        if (values[index] < -1000 || values[index] > 1000) return INVALID_RESULT;
    }

    usz weights_start = 2 + matrix_length;
    usz targets_start = weights_start + features;
    double squared_error_sum = 0.0;
    for (usz row = 0; row < observations; row++) {
        double prediction = 0.0;
        usz row_start = 2 + row * features;
        for (usz column = 0; column < features; column++) {
            prediction += (double)values[row_start + column] * (double)values[weights_start + column];
        }
        double error = prediction - (double)values[targets_start + row];
        squared_error_sum += error * error;
    }
    return squared_error_sum / (2.0 * (double)observations);
}
