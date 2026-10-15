module mean_absolute_error_loss;

const usz MAX_LENGTH = 256;
const double INVALID_RESULT = -1.0e300;

fn double mean_absolute_error_loss(long* values, usz length) @export("mean_absolute_error_loss") {
    if (values == null || length < 3 || length > 2 * MAX_LENGTH + 1) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 1 || count_value > (long)MAX_LENGTH || length != 2 * (usz)count_value + 1) {
        return INVALID_RESULT;
    }
    usz count = (usz)count_value;
    double absolute_sum = 0.0;
    for (usz index = 0; index < count; index++) {
        long predicted = values[index + 1];
        long actual = values[index + 1 + count];
        if (predicted < -1000000 || predicted > 1000000 || actual < -1000000 || actual > 1000000) {
            return INVALID_RESULT;
        }
        double difference = (double)(predicted - actual);
        if (difference < 0.0) difference = -difference;
        absolute_sum += difference;
    }
    return absolute_sum / (double)count;
}
