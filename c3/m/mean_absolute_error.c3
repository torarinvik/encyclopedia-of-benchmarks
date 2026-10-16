module mean_absolute_error;

const long MAX_COUNT = 256;
const long MAX_PARSED_COUNT = 257;
const long MAX_SAMPLE = 1000000;
const usz MAX_INPUT_LENGTH = 515;
const double INVALID_RESULT = -1.0e300;

fn double mean_absolute_error_impl(long* values, usz length) {
    if (values == null || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 0 || count_value > MAX_PARSED_COUNT) return INVALID_RESULT;
    if (length != (usz)(1 + 2 * count_value) || count_value == 0 || count_value > MAX_COUNT)
        return INVALID_RESULT;
    usz count = (usz)count_value;
    for (usz index = 0; index < count * 2; index++) {
        if (values[1 + index] < -MAX_SAMPLE || values[1 + index] > MAX_SAMPLE)
            return INVALID_RESULT;
    }
    double total = 0.0;
    for (usz index = 0; index < count; index++) {
        double difference = (double)values[1 + index] / 1000000.0 -
                            (double)values[1 + count + index] / 1000000.0;
        double residual = difference;
        if (residual < 0.0) residual = -residual;
        total += residual;
    }
    return total / (double)count;
}

fn double mean_absolute_error(long* values, usz length) @export("mean_absolute_error") {
    return mean_absolute_error_impl(values, length);
}
