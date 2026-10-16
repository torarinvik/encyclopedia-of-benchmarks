/* Selected entry in the Haskell complementary-filter scan trace. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32
#define SCALE 1000000
#define MAX_SIGNAL_MICRO 1000000
#define INVALID_RESULT (-1.0e300)

double comp_filt(const int64_t *values, size_t length)
{
    if (values == NULL || length < 6 || length > 4 + 2 * MAX_SAMPLES) return INVALID_RESULT;
    const int64_t alpha_ppm = values[0];
    const int64_t delta_t_micro = values[1];
    const int64_t count_value = values[2];
    const int64_t output_index_value = values[3];
    if (alpha_ppm < 0 || alpha_ppm > SCALE || delta_t_micro < 0 || delta_t_micro > SCALE ||
        count_value < 1 || count_value > MAX_SAMPLES || output_index_value < 0 ||
        output_index_value > count_value) return INVALID_RESULT;
    const size_t count = (size_t)count_value;
    const size_t output_index = (size_t)output_index_value;
    if (length != 4 + 2 * count) return INVALID_RESULT;
    for (size_t i = 0; i < count; ++i) {
        const int64_t rate = values[4 + i];
        const int64_t reference = values[4 + count + i];
        if (rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO ||
            reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO) return INVALID_RESULT;
    }
    const double alpha = (double)alpha_ppm / (double)SCALE;
    const double delta_t = (double)delta_t_micro / (double)SCALE;
    double theta = (double)values[4 + count] / (double)SCALE;
    for (size_t i = 0; i < output_index; ++i) {
        const double rate = (double)values[4 + i] / (double)SCALE;
        const double reference = (double)values[4 + count + i] / (double)SCALE;
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference;
    }
    return theta;
}
