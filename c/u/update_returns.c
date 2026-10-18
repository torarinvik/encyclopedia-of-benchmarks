#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_RETURNS 2
#define MAX_RETURNS 60
#define MAX_INPUT_LENGTH 62
#define MAX_OUTPUT_LENGTH 63

/* Project the updated returns, sample statistics, and post-update parametric VaR. */
int64_t update_returns(const double *input, size_t input_length,
                      double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 + MIN_RETURNS || input_length > MAX_INPUT_LENGTH)
        return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!isfinite(input[i])) return -1;
    }
    if (input[0] < (double)MIN_RETURNS || input[0] > (double)MAX_RETURNS ||
        input[0] != trunc(input[0])) return -1;
    const size_t count = (size_t)input[0];
    if (input_length != count + 1) return -1;

    double returns[MAX_RETURNS];
    double sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double value = input[i + 1];
        if (value < -0.25 || value > 0.25) return -1;
        returns[i] = value;
        sum += value;
    }
    const double mean = sum / (double)count;
    double squared_deviation_sum = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const double deviation = returns[i] - mean;
        squared_deviation_sum += deviation * deviation;
    }
    const double volatility = sqrt(squared_deviation_sum / (double)(count - 1));
    if (!isfinite(mean) || !isfinite(volatility) || volatility == 0.0) return -1;
    const double var = 100000.0 * (1.6448536269514722 * volatility - mean);
    if (!isfinite(var)) return -1;

    double staged[MAX_OUTPUT_LENGTH];
    for (size_t i = 0; i < count; ++i) staged[i] = returns[i];
    staged[count] = mean;
    staged[count + 1] = volatility;
    staged[count + 2] = var;
    const size_t result_length = count + 3;
    if (output == NULL || output_capacity < result_length) return -2;
    for (size_t i = 0; i < result_length; ++i) output[i] = staged[i];
    return (int64_t)result_length;
}
