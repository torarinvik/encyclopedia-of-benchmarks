#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)
#define MAX_PARSEABLE_INPUT_LENGTH ((size_t)69)
#define PI_VALUE 3.14159265358979323846264338327950288

static double qnorm_r_as241(double probability)
{
    const double q = probability - 0.5;
    if (fabs(q) <= 0.425) {
        const double r = 0.180625 - q * q;
        const double numerator = (((((((
            2509.0809287301226727 * r + 33430.575583588128105) * r + 67265.770927008700853) * r +
            45921.953931549871457) * r + 13731.693765509461125) * r + 1971.5909503065514427) * r +
            133.14166789178437745) * r + 3.387132872796366608);
        const double denominator = (((((((
            5226.495278852854561 * r + 28729.085735721942674) * r + 39307.89580009271061) * r +
            21213.794301586595867) * r + 5394.1960214247511077) * r + 687.1870074920579083) * r +
            42.313330701600911252) * r + 1.0);
        return q * numerator / denominator;
    }

    const double r = sqrt(-log(1.0 - probability)) - 1.6;
    const double numerator = (((((((
        0.00077454501427834140764 * r + 0.0227238449892691845833) * r +
        0.24178072517745061177) * r + 1.27045825245236838258) * r +
        3.64784832476320460504) * r + 5.7694972214606914055) * r +
        4.6303378461565452959) * r + 1.42343711074968357734);
    const double denominator = (((((((
        1.05075007164441684324e-9 * r + 0.0005475938084995344946) * r +
        0.0151986665636164571966) * r + 0.14810397642748007459) * r +
        0.68976733498510000455) * r + 1.6763848301838038494) * r +
        2.05319162663775882187) * r + 1.0);
    return numerator / denominator;
}

int64_t calculate_es_parametric(const double *input, size_t input_length,
                                double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 24 || input_length > MAX_PARSEABLE_INPUT_LENGTH)
        return INVALID_RESULT;
    for (size_t i = 0; i < input_length; ++i)
        if (!isfinite(input[i])) return INVALID_RESULT;

    const double portfolio_value = input[0];
    const double confidence_level = input[1];
    const double time_horizon = input[2];
    const double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || floor(count_value) != count_value)
        return INVALID_RESULT;
    const size_t return_count = (size_t)count_value;
    if (input_length != 4 + return_count || portfolio_value < 100.0 ||
        portfolio_value > 1000000.0 || confidence_level < 0.5 || confidence_level > 0.95 ||
        time_horizon < 1.0 || time_horizon > 10.0)
        return INVALID_RESULT;

    double returns[64];
    for (size_t i = 0; i < return_count; ++i) {
        returns[i] = input[4 + i];
        if (returns[i] < -0.25 || returns[i] > 0.25) return INVALID_RESULT;
    }
    if (output == NULL || output_capacity < 1) return OUTPUT_ERROR;

    double sum = 0.0;
    for (size_t i = 0; i < return_count; ++i) sum += returns[i];
    const double mean = sum / (double)return_count;
    double squared_deviations = 0.0;
    for (size_t i = 0; i < return_count; ++i) {
        const double difference = returns[i] - mean;
        squared_deviations += difference * difference;
    }
    const double sample_sd = sqrt(squared_deviations / (double)(return_count - 1));
    const double z = qnorm_r_as241(confidence_level);
    const double density = exp(-z * z / 2.0) / sqrt(2.0 * PI_VALUE);
    const double lambda = density / (1.0 - confidence_level);
    const double result = portfolio_value * (lambda * sample_sd - mean) * sqrt(time_horizon);
    output[0] = result;
    return 1;
}
