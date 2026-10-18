module monte_carlo_var;
import "math";

const MIN_RETURN_COUNT = 20;
const MAX_RETURN_COUNT = 64;
const MIN_SIMULATION_COUNT = 20;
const MAX_SIMULATION_COUNT = 128;
const MAX_VALID_INPUT_LENGTH = 197;
const MAX_PARSEABLE_INPUT_LENGTH = 198;

fn bool finite_value(double value) {
    return value == value && value >= -1.7976931348623157e308 &&
           value <= 1.7976931348623157e308;
}

fn double rounded_multiply(double left, double right) @noinline { return left * right; }
fn double rounded_add(double left, double right) @noinline { return left + right; }
fn double rounded_subtract(double left, double right) @noinline { return left - right; }

fn long monte_carlo_risk(double* input, usz input_length,
                         double* output, usz output_capacity,
                         bool expected_shortfall) {
    if (input == null || input_length < 45 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz index = 0; index < input_length; index++)
        if (!finite_value(input[index])) return -1;

    double portfolio = input[0], confidence = input[1], horizon = input[2];
    double simulation_value = input[3], return_count_value = input[4];
    if (portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 ||
        horizon < 1.0 || horizon > 10.0 ||
        simulation_value < (double)MIN_SIMULATION_COUNT ||
        simulation_value > (double)MAX_SIMULATION_COUNT ||
        return_count_value < (double)MIN_RETURN_COUNT ||
        return_count_value > (double)MAX_RETURN_COUNT) return -1;

    long simulation_long = (long)simulation_value;
    long return_count_long = (long)return_count_value;
    if (simulation_value != (double)simulation_long ||
        return_count_value != (double)return_count_long) return -1;
    usz simulation_count = (usz)simulation_long;
    usz return_count = (usz)return_count_long;
    usz expected_length = 5 + return_count + simulation_count;
    if (input_length != expected_length || input_length > MAX_VALID_INPUT_LENGTH) return -1;

    double returns[MAX_RETURN_COUNT] = {0.0};
    double draws[MAX_SIMULATION_COUNT] = {0.0};
    double simulated[MAX_SIMULATION_COUNT] = {0.0};
    double sum = 0.0;
    for (usz index = 0; index < return_count; index++) {
        double value = input[5 + index];
        if (value < -0.25 || value > 0.25) return -1;
        returns[index] = value;
        sum = rounded_add(sum, value);
    }
    for (usz index = 0; index < simulation_count; index++) {
        double value = input[5 + return_count + index];
        if (value < -3.0 || value > 3.0) return -1;
        draws[index] = value;
    }
    double mean = sum / (double)return_count;
    double squared_deviation = 0.0;
    for (usz index = 0; index < return_count; index++) {
        double delta = returns[index] - mean;
        squared_deviation = rounded_add(squared_deviation, rounded_multiply(delta, delta));
    }
    double volatility = math.sqrt(squared_deviation / (double)(return_count - 1));
    if (!finite_value(volatility) || volatility == 0.0) return -1;

    for (usz index = 0; index < simulation_count; index++)
        simulated[index] = rounded_add(mean, rounded_multiply(volatility, draws[index]));
    for (usz index = 1; index < simulation_count; index++) {
        double value = simulated[index];
        usz position = index;
        while (position > 0 && simulated[position - 1] > value) {
            simulated[position] = simulated[position - 1];
            position--;
        }
        simulated[position] = value;
    }

    double tail_value = math.floor((1.0 - confidence) * (double)simulation_count);
    if (tail_value < 1.0 || tail_value > (double)simulation_count) return -1;
    usz tail_count = (usz)(long)tail_value;
    double metric;
    if (expected_shortfall) {
        double tail_sum = 0.0;
        for (usz index = 0; index < tail_count; index++)
            tail_sum = rounded_add(tail_sum, simulated[index]);
        metric = rounded_multiply(
            rounded_multiply(-(tail_sum / (double)tail_count), portfolio), math.sqrt(horizon));
    } else {
        metric = rounded_multiply(
            rounded_multiply(-simulated[tail_count - 1], portfolio), math.sqrt(horizon));
    }
    if (!finite_value(metric)) return -1;
    if (output == null || output_capacity < 1) return -2;
    output[0] = metric;
    return 1;
}

fn long monte_carlo_var(double* input, usz input_length, double* output, usz output_capacity)
    @export("monte_carlo_var") {
    return monte_carlo_risk(input, input_length, output, output_capacity, false);
}
