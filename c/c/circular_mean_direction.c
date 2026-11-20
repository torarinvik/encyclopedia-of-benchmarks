#include <math.h>
#include <stddef.h>
#include <stdint.h>

static const double CMD_PI = 3.14159265358979323846264338327950288;
static const double CMD_TAU = 6.28318530717958647692528676655900576;

static double cmd_wrap(double angle) {
    double value = angle - floor((angle + CMD_PI) / CMD_TAU) * CMD_TAU;
    if (value >= CMD_PI) value -= CMD_TAU;
    if (value < -CMD_PI) value += CMD_TAU;
    return value;
}

int64_t circular_mean_direction(const double *input, size_t length,
                                double *output, size_t capacity) {
    if (input == NULL || length < 2 || length > 66) return -1;
    const double count_value = input[0];
    if (!isfinite(count_value) || trunc(count_value) != count_value ||
        count_value < 1.0 || count_value > 64.0) return -1;
    const size_t count = (size_t)count_value;
    if (length != count + 1) return -1;

    double sum_cos = 0.0, sum_sin = 0.0;
    double correction_cos = 0.0, correction_sin = 0.0;
    const double angle_bound = 8.0 * CMD_PI;
    for (size_t index = 0; index < count; ++index) {
        const double raw = input[index + 1];
        if (!isfinite(raw) || fabs(raw) > angle_bound) return -1;
        const double angle = cmd_wrap(raw);
        const double adjusted_cos = cos(angle) - correction_cos;
        const double next_cos = sum_cos + adjusted_cos;
        correction_cos = (next_cos - sum_cos) - adjusted_cos;
        sum_cos = next_cos;
        const double adjusted_sin = sin(angle) - correction_sin;
        const double next_sin = sum_sin + adjusted_sin;
        correction_sin = (next_sin - sum_sin) - adjusted_sin;
        sum_sin = next_sin;
    }
    const double resultant = sqrt(sum_cos * sum_cos + sum_sin * sum_sin);
    if (!isfinite(resultant) || resultant <= (double)count * 0x1p-28) return -1;
    if (output == NULL || capacity < 1) return -2;
    output[0] = cmd_wrap(atan2(sum_sin, sum_cos));
    return 1;
}
