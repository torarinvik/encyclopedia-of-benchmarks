module generate_risk_report;

extern fn double sqrt(double value);
extern fn double log(double value);
extern fn double exp(double value);

const usz MAX_INPUT_LENGTH = 69;
const double PI_VALUE = 3.14159265358979323846264338327950288;

fn bool finite_value(double value) {
    return value == value && value < 1e300 && value > -1e300;
}

fn double qnorm_r_as241(double probability) {
    double q = probability - 0.5;
    if (q < 0.425 && q > -0.425) {
        double r = 0.180625 - q * q;
        double numerator = 2509.0809287301226727;
        numerator = numerator * r + 33430.575583588128105;
        numerator = numerator * r + 67265.770927008700853;
        numerator = numerator * r + 45921.953931549871457;
        numerator = numerator * r + 13731.693765509461125;
        numerator = numerator * r + 1971.5909503065514427;
        numerator = numerator * r + 133.14166789178437745;
        numerator = numerator * r + 3.387132872796366608;
        double denominator = 5226.495278852854561;
        denominator = denominator * r + 28729.085735721942674;
        denominator = denominator * r + 39307.89580009271061;
        denominator = denominator * r + 21213.794301586595867;
        denominator = denominator * r + 5394.1960214247511077;
        denominator = denominator * r + 687.1870074920579083;
        denominator = denominator * r + 42.313330701600911252;
        denominator = denominator * r + 1.0;
        return q * numerator / denominator;
    }
    double r = sqrt(-log(1.0 - probability)) - 1.6;
    double numerator = 0.00077454501427834140764;
    numerator = numerator * r + 0.0227238449892691845833;
    numerator = numerator * r + 0.24178072517745061177;
    numerator = numerator * r + 1.27045825245236838258;
    numerator = numerator * r + 3.64784832476320460504;
    numerator = numerator * r + 5.7694972214606914055;
    numerator = numerator * r + 4.6303378461565452959;
    numerator = numerator * r + 1.42343711074968357734;
    double denominator = 1.05075007164441684324e-9;
    denominator = denominator * r + 0.0005475938084995344946;
    denominator = denominator * r + 0.0151986665636164571966;
    denominator = denominator * r + 0.14810397642748007459;
    denominator = denominator * r + 0.68976733498510000455;
    denominator = denominator * r + 1.6763848301838038494;
    denominator = denominator * r + 2.05319162663775882187;
    denominator = denominator * r + 1.0;
    return numerator / denominator;
}

fn long generate_risk_report(double* input, usz input_length, double* output, usz capacity) @export("generate_risk_report") {
    if (input == null || input_length < 24 || input_length > MAX_INPUT_LENGTH) return -1L;
    for (usz i = 0; i < input_length; i++) if (!finite_value(input[i])) return -1L;
    double portfolio = input[0], confidence = input[1], horizon = input[2], count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || (double)(long)count_value != count_value) return -1L;
    usz count = (usz)(long)count_value;
    if (input_length != 4 + count || portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 || horizon < 1.0 || horizon > 10.0) return -1L;
    double[64] sorted_returns = zeroed;
    double sum = 0.0;
    for (usz i = 0; i < count; i++) {
        double value = input[4 + i];
        if (value < -0.25 || value > 0.25) return -1L;
        sorted_returns[i] = value;
        sum += value;
    }
    double mean = sum / (double)count;
    double squared_deviations = 0.0;
    for (usz i = 0; i < count; i++) {
        double difference = sorted_returns[i] - mean;
        squared_deviations += difference * difference;
    }
    double sample_sd = sqrt(squared_deviations / (double)(count - 1));
    if (sample_sd == 0.0) return -1L;
    usz tail_count = (usz)((1.0 - confidence) * (double)count);
    if (tail_count < 1) return -1L;
    for (usz i = 1; i < count; i++) {
        double value = sorted_returns[i];
        usz position = i;
        while (position > 0 && sorted_returns[position - 1] > value) {
            sorted_returns[position] = sorted_returns[position - 1];
            position--;
        }
        sorted_returns[position] = value;
    }
    double tail_sum = 0.0;
    for (usz i = 0; i < tail_count; i++) tail_sum += sorted_returns[i];
    double horizon_scale = sqrt(horizon);
    double z = qnorm_r_as241(confidence);
    double density = exp(-0.5 * z * z) / sqrt(2.0 * PI_VALUE);
    double es_multiplier = density / (1.0 - confidence);
    double third_moment = 0.0, fourth_moment = 0.0;
    for (usz i = 0; i < count; i++) {
        double difference = sorted_returns[i] - mean;
        double square = difference * difference;
        third_moment += square * difference;
        fourth_moment += square * square;
    }
    third_moment /= (double)count;
    fourth_moment /= (double)count;
    double[8] staged = zeroed;
    staged[0] = -sorted_returns[tail_count - 1] * portfolio * horizon_scale;
    staged[1] = -(tail_sum / (double)tail_count) * portfolio * horizon_scale;
    staged[2] = portfolio * (z * sample_sd - mean) * horizon_scale;
    staged[3] = portfolio * (es_multiplier * sample_sd - mean) * horizon_scale;
    staged[4] = mean;
    staged[5] = sample_sd;
    staged[6] = third_moment / (sample_sd * sample_sd * sample_sd);
    staged[7] = fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0;
    if (output == null || capacity < 8) return -2L;
    for (usz i = 0; i < 8; i++) output[i] = staged[i];
    return 8L;
}
