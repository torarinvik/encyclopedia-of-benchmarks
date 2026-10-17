module linear_regression_vectorized;

const usz MAX_PARSEABLE_INPUT_LENGTH = 45;
const usz MAX_SAMPLES = 8;
const usz MAX_FEATURES = 4;
const usz MAX_FEATURE_VALUES = MAX_SAMPLES * MAX_FEATURES;

fn long linear_regression_vectorized(double* input, usz length,
        double* output, usz output_capacity) @export("linear_regression_vectorized") {
    if (input == null || length < 4 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    double sample_value = input[0], feature_value = input[1], iteration_value = input[2];
    if (sample_value != sample_value || sample_value < 2.0 || sample_value > (double)MAX_SAMPLES ||
        feature_value != feature_value || feature_value < 2.0 || feature_value > (double)MAX_FEATURES ||
        iteration_value != iteration_value || iteration_value < 10.0 || iteration_value > 128.0) return -1;
    usz sample_count = (usz)sample_value;
    usz feature_count = (usz)feature_value;
    usz iterations = (usz)iteration_value;
    if ((double)sample_count != sample_value || (double)feature_count != feature_value ||
        (double)iterations != iteration_value) return -1;
    if (length != 4 + sample_count * feature_count + sample_count) return -1;

    double alpha = input[3];
    if (alpha != alpha || alpha < 0.0001 || alpha > 0.01) return -1;

    double[MAX_FEATURE_VALUES] features;
    double[MAX_SAMPLES] labels;
    usz feature_values = sample_count * feature_count;
    for (usz index = 0; index < feature_values; index++) {
        double value = input[4 + index];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        features[index] = value;
    }
    for (usz row = 0; row < sample_count; row++)
        if (features[row * feature_count] != 1.0) return -1;
    for (usz row = 0; row < sample_count; row++) {
        double value = input[4 + feature_values + row];
        if (value != value || value < -1.0 || value > 1.0) return -1;
        labels[row] = value;
    }
    if (output == null || output_capacity < feature_count) return -2;

    double[MAX_FEATURES] theta;
    double[MAX_SAMPLES] errors;
    double[MAX_FEATURES] gradients;
    for (usz column = 0; column < feature_count; column++) theta[column] = 0.0;
    for (usz iteration = 0; iteration < iterations; iteration++) {
        for (usz row = 0; row < sample_count; row++) {
            double prediction = 0.0;
            for (usz column = 0; column < feature_count; column++)
                prediction += features[row * feature_count + column] * theta[column];
            errors[row] = prediction - labels[row];
        }
        for (usz column = 0; column < feature_count; column++) {
            double gradient = 0.0;
            for (usz row = 0; row < sample_count; row++)
                gradient += features[row * feature_count + column] * errors[row];
            gradients[column] = gradient / (double)sample_count;
        }
        for (usz column = 0; column < feature_count; column++)
            theta[column] -= alpha * gradients[column];
    }
    for (usz column = 0; column < feature_count; column++) output[column] = theta[column];
    return (long)feature_count;
}
