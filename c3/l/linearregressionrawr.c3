module linearregressionrawr;

const usz MIN_SAMPLE_COUNT = 2;
const usz MAX_SAMPLE_COUNT = 32;
const usz MAX_PARSEABLE_INPUT_LENGTH = 66;
const usz MAX_OUTPUT_ELEMENTS = 2;
const double MAX_FINITE = 1.7976931348623157e308;

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn bool exact_integer_in_range(double value, long minimum, long maximum) {
    if (!finite_value(value) || value < (double)minimum || value > (double)maximum) return false;
    return value == (double)(long)value;
}

fn double rounded_divide(double numerator, double denominator) @noinline {
    return numerator / denominator;
}

fn long linearregressionrawr(double* input, usz input_length,
                             double* output, usz output_capacity)
    @export("linearregressionrawr")
{
    if (input == null || input_length == 0 ||
        input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz index = 0; index < input_length; index++) {
        if (!finite_value(input[index])) return -1;
    }

    if (!exact_integer_in_range(input[0], (long)MIN_SAMPLE_COUNT,
                                (long)MAX_SAMPLE_COUNT)) return -1;
    usz sample_count = (usz)input[0];
    if (input_length != 1 + 2 * sample_count) return -1;

    long predictor_sum = 0;
    long response_sum = 0;
    long cross_product_sum = 0;
    long predictor_square_sum = 0;
    long first_predictor = 0;
    bool predictors_are_constant = true;
    for (usz index = 0; index < sample_count; index++) {
        double predictor_value = input[1 + index];
        double response_value = input[1 + sample_count + index];
        if (!exact_integer_in_range(predictor_value, -4, 4) ||
            !exact_integer_in_range(response_value, -16, 16)) return -1;

        long predictor = (long)predictor_value;
        long response = (long)response_value;
        if (index == 0) first_predictor = predictor;
        else if (predictor != first_predictor) predictors_are_constant = false;

        predictor_sum += predictor;
        response_sum += response;
        cross_product_sum += predictor * response;
        predictor_square_sum += predictor * predictor;
    }
    if (predictor_sum != 0 || predictors_are_constant || predictor_square_sum == 0) return -1;

    double[MAX_OUTPUT_ELEMENTS] results = zeroed;
    results[0] = rounded_divide((double)response_sum, (double)sample_count);
    results[1] = rounded_divide((double)cross_product_sum, (double)predictor_square_sum);
    if (output == null || output_capacity < MAX_OUTPUT_ELEMENTS) return -2;
    for (usz index = 0; index < MAX_OUTPUT_ELEMENTS; index++) output[index] = results[index];
    return (long)MAX_OUTPUT_ELEMENTS;
}
