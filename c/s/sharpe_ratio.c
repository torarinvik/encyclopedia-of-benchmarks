#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_PARSEABLE_LENGTH 67u
#define MAX_SAMPLE_COUNT 64
#define SCALE 1000000.0
#define MIN_RETURN_MICRO (-200000)
#define MAX_RETURN_MICRO 200000
#define MIN_RISK_FREE_MICRO (-100000)
#define MAX_RISK_FREE_MICRO 100000
#define INVALID_RESULT (-1.0e300)

double sharpe_ratio(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2u || length > MAX_PARSEABLE_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 2 || count_value > MAX_SAMPLE_COUNT
        || length != (size_t)count_value + 2u) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    const int64_t risk_free_micro = values[count + 1u];
    if (risk_free_micro < MIN_RISK_FREE_MICRO || risk_free_micro > MAX_RISK_FREE_MICRO)
        return INVALID_RESULT;

    double sum = 0.0;
    int constant_returns = 1;
    for (size_t index = 0; index < count; ++index) {
        const int64_t return_micro = values[index + 1u];
        if (return_micro < MIN_RETURN_MICRO || return_micro > MAX_RETURN_MICRO)
            return INVALID_RESULT;
        if (return_micro != values[1]) constant_returns = 0;
        sum += (double)return_micro / SCALE;
    }
    if (constant_returns) return INVALID_RESULT;

    const double mean = sum / (double)count;
    const double risk_free_rate = (double)risk_free_micro / SCALE;
    const double excess_return = mean - risk_free_rate;
    double squared_deviations = 0.0;
    for (size_t index = 0; index < count; ++index) {
        const double return_value = (double)values[index + 1u] / SCALE;
        const double difference = return_value - mean;
        squared_deviations += pow(difference, 2.0);
    }
    const double variance = squared_deviations / (double)(count - 1u);
    const double standard_deviation = sqrt(variance);
    if (standard_deviation == 0.0) return INVALID_RESULT;
    return excess_return / standard_deviation;
}
