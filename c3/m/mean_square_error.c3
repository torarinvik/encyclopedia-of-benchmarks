module mean_square_error;

const usz MAX_LENGTH = 256;
const double INVALID_RESULT = -1.0e300;

fn double mean_square_error(long* values, usz length) @export("mean_square_error") {
    if (values == null || length < 3 || length > 2 * MAX_LENGTH + 1) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_LENGTH || length != 2 * (usz)count_value + 1) {
        return INVALID_RESULT;
    }
    usz count = (usz)count_value;
    double error_sum = 0.0;
    for (usz index = 0; index < count; index++) {
        long predicted = values[index + 1];
        long expected = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || expected < -1000000 || expected > 1000000) {
            return INVALID_RESULT;
        }
        double difference = (double)(expected - predicted);
        error_sum += difference * difference;
    }
    return error_sum / (double)count;
}
