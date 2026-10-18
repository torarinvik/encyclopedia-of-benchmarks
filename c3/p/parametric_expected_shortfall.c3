module parametric_expected_shortfall;

extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);
extern fn double fabs(double value);

const usz MAX_PARSEABLE_INPUT_LENGTH = 69;
const double MAX_FINITE = 1.7976931348623157e308;
const double PI_VALUE = 3.14159265358979323846264338327950288;

fn bool finite_value(double value) {
    return value == value && value <= MAX_FINITE && value >= -MAX_FINITE;
}

fn double qnorm_r_as241(double probability) {
    double q = probability - 0.5;
    if (fabs(q) <= 0.425) {
        double r = 0.180625 - q * q;
        double numerator = (((((((
            2509.0809287301226727 * r + 33430.575583588128105) * r + 67265.770927008700853) * r +
            45921.953931549871457) * r + 13731.693765509461125) * r + 1971.5909503065514427) * r +
            133.14166789178437745) * r + 3.387132872796366608);
        double denominator = (((((((
            5226.495278852854561 * r + 28729.085735721942674) * r + 39307.89580009271061) * r +
            21213.794301586595867) * r + 5394.1960214247511077) * r + 687.1870074920579083) * r +
            42.313330701600911252) * r + 1.0);
        return q * numerator / denominator;
    }
    double r = sqrt(-log(1.0 - probability)) - 1.6;
    double numerator = (((((((
        0.00077454501427834140764 * r + 0.0227238449892691845833) * r +
        0.24178072517745061177) * r + 1.27045825245236838258) * r +
        3.64784832476320460504) * r + 5.7694972214606914055) * r +
        4.6303378461565452959) * r + 1.42343711074968357734);
    double denominator = (((((((
        1.05075007164441684324e-9 * r + 0.0005475938084995344946) * r +
        0.0151986665636164571966) * r + 0.14810397642748007459) * r +
        0.68976733498510000455) * r + 1.6763848301838038494) * r +
        2.05319162663775882187) * r + 1.0);
    return numerator / denominator;
}

fn long calculate_es_parametric(double* input, usz input_length,
                                double* output, usz output_capacity)
    @export("calculate_es_parametric") {
    if (input == null || input_length < 24 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (usz i = 0; i < input_length; i++) {
        if (!finite_value(input[i])) return -1;
    }

    double portfolio_value = input[0];
    double confidence_level = input[1];
    double time_horizon = input[2];
    double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || count_value != (double)(long)count_value) return -1;
    usz return_count = (usz)count_value;
    if (input_length != 4 + return_count || portfolio_value < 100.0 || portfolio_value > 1000000.0 ||
        confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0)
        return -1;

    double[64] returns = zeroed;
    for (usz i = 0; i < return_count; i++) {
        returns[i] = input[4 + i];
        if (returns[i] < -0.25 || returns[i] > 0.25) return -1;
    }
    if (output == null || output_capacity < 1) return -2;

    double sum = 0.0;
    for (usz i = 0; i < return_count; i++) sum += returns[i];
    double mean = sum / (double)return_count;
    double squared_deviations = 0.0;
    for (usz i = 0; i < return_count; i++) {
        double difference = returns[i] - mean;
        squared_deviations += difference * difference;
    }
    double sample_sd = sqrt(squared_deviations / (double)(return_count - 1));
    double z = qnorm_r_as241(confidence_level);
    double density = exp(-z * z / 2.0) / sqrt(2.0 * PI_VALUE);
    double lambda = density / (1.0 - confidence_level);
    output[0] = portfolio_value * (lambda * sample_sd - mean) * sqrt(time_horizon);
    return 1;
}
