#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_SAMPLE_COUNT INT64_C(64)
#define MAX_INPUT_LENGTH ((size_t)68)
#define MIN_SAMPLE_MICRO INT64_C(-1000000)
#define MAX_SAMPLE_MICRO INT64_C(1000000)
#define INVALID_RESULT (-1.0e300)

double laplace_transformation(const int64_t *input, size_t length) {
    if (input == NULL || length < 3 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const int64_t sample_count_value = input[0];
    const int64_t s_milli = input[1];
    const int64_t dt_micro = input[2];
    if (sample_count_value < 1 || sample_count_value > MAX_SAMPLE_COUNT) return INVALID_RESULT;
    const size_t sample_count = (size_t)sample_count_value;
    if (length != sample_count + 3 || s_milli < 0 || s_milli > 1000 ||
        dt_micro < 1 || dt_micro > 1000000) return INVALID_RESULT;

    double samples[MAX_SAMPLE_COUNT];
    for (size_t index = 0; index < sample_count; ++index) {
        const int64_t sample = input[3 + index];
        if (sample < MIN_SAMPLE_MICRO || sample > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        samples[index] = (double)sample / 1000000.0;
    }
    if (sample_count == 1) return 0.0;

    const double s_value = (double)s_milli / 1000.0;
    const double delta_t = (double)dt_micro / 1000000.0;
    const double stop = (double)(sample_count - 1) * delta_t;
    const double step = stop / (double)(sample_count - 1);
    double integrand[MAX_SAMPLE_COUNT];
    for (size_t index = 0; index < sample_count; ++index) {
        const double time = index == sample_count - 1 ? stop : (double)index * step;
        integrand[index] = samples[index] * exp(-s_value * time);
    }

    double result = 0.0;
    for (size_t index = 0; index + 1 < sample_count; ++index)
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0;
    return result;
}
