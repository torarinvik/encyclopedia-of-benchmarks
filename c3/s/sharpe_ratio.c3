module sharpe_ratio;

extern fn double pow(double base, double exponent);
extern fn double sqrt(double value);
const usz MAX_PARSEABLE_LENGTH = 67;
const long MAX_SAMPLE_COUNT = 64;
const double SCALE = 1000000.0;
const long MIN_RETURN_MICRO = -200000;
const long MAX_RETURN_MICRO = 200000;
const long MIN_RISK_FREE_MICRO = -100000;
const long MAX_RISK_FREE_MICRO = 100000;
const double INVALID_RESULT = -1.0e300;

double sharpe_ratio(long* values, usz length) @export("sharpe_ratio") {
    if (values == null || length < 2 || length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    long count_value = values[0];
    if (count_value < 2 || count_value > MAX_SAMPLE_COUNT
        || length != (usz)count_value + 2) return INVALID_RESULT;
    usz count = (usz)count_value;
    long risk_free_micro = values[count + 1];
    if (risk_free_micro < MIN_RISK_FREE_MICRO || risk_free_micro > MAX_RISK_FREE_MICRO)
        return INVALID_RESULT;

    double sum = 0.0;
    bool constant_returns = true;
    for (usz index = 0; index < count; index += 1) {
        long return_micro = values[index + 1];
        if (return_micro < MIN_RETURN_MICRO || return_micro > MAX_RETURN_MICRO)
            return INVALID_RESULT;
        if (return_micro != values[1]) constant_returns = false;
        sum += (double)return_micro / SCALE;
    }
    if (constant_returns) return INVALID_RESULT;

    double mean = sum / (double)count;
    double risk_free_rate = (double)risk_free_micro / SCALE;
    double excess_return = mean - risk_free_rate;
    double squared_deviations = 0.0;
    for (usz index = 0; index < count; index += 1) {
        double return_value = (double)values[index + 1] / SCALE;
        double difference = return_value - mean;
        squared_deviations += pow(difference, 2.0);
    }
    double variance = squared_deviations / (double)(count - 1);
    double standard_deviation = sqrt(variance);
    if (standard_deviation == 0.0) return INVALID_RESULT;
    return excess_return / standard_deviation;
}
