#include <math.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define INVALID_RESULT INT64_C(-1)
#define OUTPUT_ERROR INT64_C(-2)
#define MAX_PARSEABLE_INPUT_LENGTH ((size_t)69)

static int compare_f64(const void *left, const void *right)
{
    const double a = *(const double *)left;
    const double b = *(const double *)right;
    return (a > b) - (a < b);
}

int64_t historical_expected_shortfall(const double *input, size_t input_length,
                                      double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 24 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return INVALID_RESULT;
    for (size_t i = 0; i < input_length; ++i)
        if (!isfinite(input[i])) return INVALID_RESULT;
    const double portfolio_value = input[0];
    const double confidence_level = input[1];
    const double time_horizon = input[2];
    const double count_value = input[3];
    if (count_value < 20.0 || count_value > 64.0 || floor(count_value) != count_value) return INVALID_RESULT;
    const size_t return_count = (size_t)count_value;
    if (input_length != 4 + return_count || portfolio_value < 100.0 || portfolio_value > 1000000.0 ||
        confidence_level < 0.5 || confidence_level > 0.95 || time_horizon < 1.0 || time_horizon > 10.0)
        return INVALID_RESULT;

    double sorted_returns[64];
    for (size_t i = 0; i < return_count; ++i) {
        const double value = input[4 + i];
        if (value < -0.25 || value > 0.25) return INVALID_RESULT;
        sorted_returns[i] = value;
    }
    const int index = (int)floor((1.0 - confidence_level) * (double)return_count);
    if (index < 1) return INVALID_RESULT;
    qsort(sorted_returns, return_count, sizeof(sorted_returns[0]), compare_f64);
    double tail_sum = 0.0;
    for (int i = 0; i < index; ++i) tail_sum += sorted_returns[i];
    double result = -(tail_sum / (double)index) * portfolio_value;
    result *= sqrt(time_horizon);

    if (output == NULL || output_capacity < 1) return OUTPUT_ERROR;
    output[0] = result;
    return 1;
}
