#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLES 32
#define SCALE 1000000
#define MAX_SIGNAL_MICRO 1000000
#define INVALID_RESULT (-1.0e300)

double complementary_filter(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t coefficient_ppm = values[0];
    const int64_t sample_count_value = values[1];
    if (coefficient_ppm < 1 || coefficient_ppm >= SCALE ||
        sample_count_value < 1 || sample_count_value > MAX_SAMPLES) return INVALID_RESULT;
    const size_t sample_count = (size_t)sample_count_value;
    if (length != 2 + 3 * sample_count) return INVALID_RESULT;

    for (size_t sample = 0; sample < sample_count; ++sample) {
        const int64_t rate = values[2 + 3 * sample];
        const int64_t reference = values[3 + 3 * sample];
        const int64_t elapsed = values[4 + 3 * sample];
        if (rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO ||
            reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO ||
            elapsed < 1 || elapsed > SCALE) return INVALID_RESULT;
    }

    const double coefficient = (double)coefficient_ppm / (double)SCALE;
    double value = 0.0;
    for (size_t sample = 0; sample < sample_count; ++sample) {
        const double rate = (double)values[2 + 3 * sample] / (double)SCALE;
        const double reference = (double)values[3 + 3 * sample] / (double)SCALE;
        const double elapsed = (double)values[4 + 3 * sample] / (double)SCALE;
        if (sample == 0) value = reference;
        else value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference;
    }
    return value;
}
