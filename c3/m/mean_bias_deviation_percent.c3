module mean_bias_deviation_percent;

const double INVALID_RESULT = -1.0e300;

fn double mean_bias_deviation_percent(long* input, usz length)
    @export("mean_bias_deviation_percent") {
    if (input == null || length < 1 || length > 131) return INVALID_RESULT;
    if (input[0] < 1 || input[0] > 64) return INVALID_RESULT;
    usz count = (usz)input[0];
    if (length != 1 + 2 * count) return INVALID_RESULT;
    long difference_sum = 0, actual_sum = 0;
    for (usz index = 0; index < count; index++) {
        long prediction = input[1 + index], actual = input[1 + count + index];
        if (prediction < -1000 || prediction > 1000 || actual < -1000 || actual > 1000) return INVALID_RESULT;
        difference_sum += prediction - actual;
        actual_sum += actual;
    }
    if (actual_sum == 0) return INVALID_RESULT;
    double numerator = (double)difference_sum / (double)count;
    double denominator = (double)actual_sum / (double)count;
    return numerator / denominator * 100.0;
}
