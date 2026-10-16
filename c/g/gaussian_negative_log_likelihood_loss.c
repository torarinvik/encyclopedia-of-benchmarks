#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_COUNT 256
#define MAX_INPUT_LENGTH (1 + 3 * MAX_COUNT)
#define INVALID_RESULT (-1.0e300)

double gaussian_negative_log_likelihood_loss(const int64_t *values, size_t length)
{
    if (values == NULL || length < 4 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t count_value = values[0];
    if (count_value < 1 || count_value > MAX_COUNT) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    if (length != 1 + 3 * count) return INVALID_RESULT;

    double total = 0.0;
    for (size_t i = 0; i < count; ++i) {
        const int64_t y_scaled = values[1 + i];
        const int64_t mu_scaled = values[1 + count + i];
        const int64_t variance_nano = values[1 + 2 * count + i];
        if (y_scaled < -1000000 || y_scaled > 1000000 ||
            mu_scaled < -1000000 || mu_scaled > 1000000 ||
            variance_nano < 1 || variance_nano > 1000000000) return INVALID_RESULT;
        const double y = (double)y_scaled / 1000000.0;
        const double mu = (double)mu_scaled / 1000000.0;
        double variance = (double)variance_nano / 1000000000.0;
        if (variance < 1e-6) variance = 1e-6;
        const double residual = y - mu;
        const double loss_var = 0.5 * log(variance);
        const double loss_exp = 0.5 * ((residual * residual) / variance);
        total += loss_var + loss_exp;
    }
    return total / (double)count;
}
