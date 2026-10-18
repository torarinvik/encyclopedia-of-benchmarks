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
        const double numerator = (((((((2509.0809287301226727 * r + 33430.575583588128105) * r + 67265.770927008700853) * r +
            45921.953931549871457) * r + 13731.693765509461125) * r + 1971.5909503065514427) * r +
            133.14166789178437745) * r + 3.387132872796366608);
        const double denominator = ((((((5226.495278852854561 * r + 28729.085735721942674) * r + 39307.89580009271061) * r +
            21213.794301586595867) * r + 5394.1960214247511077) * r + 687.1870074920579083) * r +
            42.313330701600911252) * r + 1.0;
        return q * numerator / denominator;
    }
    const double r = sqrt(-log(1.0 - probability)) - 1.6;
    const double numerator = (((((((0.00077454501427834140764 * r + 0.0227238449892691845833) * r +
        0.24178072517745061177) * r + 1.27045825245236838258) * r + 3.64784832476320460504) * r +
        5.7694972214606914055) * r + 4.6303378461565452959) * r + 1.42343711074968357734);
    const double denominator = (((((((1.05075007164441684324e-9 * r + 0.0005475938084995344946) * r +
        0.0151986665636164571966) * r + 0.14810397642748007459) * r + 0.68976733498510000455) * r +
        1.6763848301838038494) * r + 2.05319162663775882187) * r + 1.0);
    return numerator / denominator;
}

int64_t generate_risk_report(const double *input, size_t input_length,
                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 24 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t i = 0; i < input_length; ++i) if (!isfinite(input[i])) return INVALID_RESULT;
    const double portfolio = input[0];
    const double confidence = input[1];
    const double horizon = input[2];
    const double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || floor(count_value) != count_value) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (input_length != 4 + count || portfolio < 100.0 || portfolio > 1000000.0 ||
        confidence < 0.5 || confidence > 0.95 || horizon < 1.0 || horizon > 10.0) return INVALID_RESULT;

    double sorted_returns[64];
    double sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double value = input[4 + i];
        if (value < -0.25 || value > 0.25) return INVALID_RESULT;
        sorted_returns[i] = value;
        sum += value;
    }
    const double mean = sum / (double)count;
    double squared_deviations = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double difference = sorted_returns[i] - mean;
        squared_deviations += difference * difference;
    }
    const double sample_sd = sqrt(squared_deviations / (double)(count - 1));
    if (sample_sd == 0.0) return INVALID_RESULT;
    const size_t tail_count = (size_t)floor((1.0 - confidence) * (double)count);
    if (tail_count < 1) return INVALID_RESULT;

    for (size_t i = 1; i < count; ++i) {
        const double value = sorted_returns[i];
        size_t position = i;
        while (position > 0 && sorted_returns[position - 1] > value) {
            sorted_returns[position] = sorted_returns[position - 1];
            --position;
        }
        sorted_returns[position] = value;
    }
    double tail_sum = 0.0;
    for (size_t i = 0; i < tail_count; ++i) tail_sum += sorted_returns[i];
    const double horizon_scale = sqrt(horizon);
    const double z = qnorm_r_as241(confidence);
    const double density = exp(-0.5 * z * z) / sqrt(2.0 * PI_VALUE);
    const double es_multiplier = density / (1.0 - confidence);
    double third_moment = 0.0;
    double fourth_moment = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double difference = sorted_returns[i] - mean;
        const double square = difference * difference;
        third_moment += square * difference;
        fourth_moment += square * square;
    }
    third_moment /= (double)count;
    fourth_moment /= (double)count;
    double result[8];
    result[0] = -sorted_returns[tail_count - 1] * portfolio * horizon_scale;
    result[1] = -(tail_sum / (double)tail_count) * portfolio * horizon_scale;
    result[2] = portfolio * (z * sample_sd - mean) * horizon_scale;
    result[3] = portfolio * (es_multiplier * sample_sd - mean) * horizon_scale;
    result[4] = mean;
    result[5] = sample_sd;
    result[6] = third_moment / (sample_sd * sample_sd * sample_sd);
    result[7] = fourth_moment / (sample_sd * sample_sd * sample_sd * sample_sd) - 3.0;

    if (output == NULL || output_capacity < 8) return OUTPUT_ERROR;
    for (size_t i = 0; i < 8; ++i) output[i] = result[i];
    return 8;
}
