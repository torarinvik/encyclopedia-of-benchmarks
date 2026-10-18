module update_returns;

const usz MIN_RETURNS = 2;
const usz MAX_RETURNS = 60;
const usz MAX_INPUT_LENGTH = 62;
const usz MAX_OUTPUT_LENGTH = 63;
const double Z_95 = 1.6448536269514722;

fn bool finite_value(double x) { return x == x && x < 1e300 && x > -1e300; }

fn long update_returns(double* input, usz input_length, double* output, usz output_capacity)
    @export("update_returns") {
    if (input == null || input_length < 1 + MIN_RETURNS || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;
    if (input[0] < (double)MIN_RETURNS || input[0] > (double)MAX_RETURNS ||
        (double)(long)input[0] != input[0]) return -1L;
    usz count = (usz)(long)input[0];
    if (input_length != count + 1) return -1L;

    double[MAX_RETURNS] returns = zeroed;
    double sum = 0.0;
    for (usz i = 0; i < count; i++) {
        double value = input[i + 1];
        if (value < -0.25 || value > 0.25) return -1L;
        returns[i] = value;
        sum += value;
    }
    double mean = sum / (double)count;
    double squared_deviation_sum = 0.0;
    for (usz i = 0; i < count; i++) {
        double deviation = returns[i] - mean;
        squared_deviation_sum += deviation * deviation;
    }
    double volatility = sqrt(squared_deviation_sum / (double)(count - 1));
    if (!finite_value(mean) || !finite_value(volatility) || volatility == 0.0) return -1L;
    double var = 100000.0 * (Z_95 * volatility - mean);
    if (!finite_value(var)) return -1L;

    double[MAX_OUTPUT_LENGTH] staged = zeroed;
    for (usz i = 0; i < count; i++) staged[i] = returns[i];
    staged[count] = mean;
    staged[count + 1] = volatility;
    staged[count + 2] = var;
    usz result_length = count + 3;
    if (output == null || output_capacity < result_length) return -2L;
    for (usz i = 0; i < result_length; i++) output[i] = staged[i];
    return (long)result_length;
}
