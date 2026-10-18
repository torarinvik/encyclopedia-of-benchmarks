module historical_expected_shortfall;

extern fn double sqrt(double value);

const usz MAX_INPUT_LENGTH = 69;

fn bool finite_value(double value) {
    return value == value && value < 1e300 && value > -1e300;
}

fn long historical_expected_shortfall(double* input, usz input_length, double* output, usz output_capacity) @export("historical_expected_shortfall") {
    if (input == null || input_length < 24 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;
    double portfolio_value = input[0];
    double confidence_level = input[1];
    double time_horizon = input[2];
    double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || (double)(long)count_value != count_value) return -1L;
    usz return_count = (usz)(long)count_value;
    if (input_length != 4 + return_count || portfolio_value < 100.0 || portfolio_value > 1000000.0 ||
        confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0) return -1L;
    double[64] sorted_returns = zeroed;
    for (usz i = 0; i < return_count; i++) {
        double value = input[4 + i];
        if (value < -0.25 || value > 0.25) return -1L;
        usz position = i;
        while (position > 0 && sorted_returns[position - 1] > value) {
            sorted_returns[position] = sorted_returns[position - 1];
            position--;
        }
        sorted_returns[position] = value;
    }
    long index = (long)((1.0 - confidence_level) * (double)return_count);
    if (index < 1) return -1L;
    double tail_sum = 0.0;
    for (long i = 0; i < index; i++) tail_sum += sorted_returns[(usz)i];
    double result = -(tail_sum / (double)index) * portfolio_value;
    result *= sqrt(time_horizon);
    if (output == null || output_capacity < 1) return -2L;
    output[0] = result;
    return 1L;
}
