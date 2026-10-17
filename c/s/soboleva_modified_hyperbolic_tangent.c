#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MIN_SAMPLE_COUNT 1
#define MAX_SAMPLE_COUNT 32
#define MAX_PARSEABLE_INPUT_LENGTH 38

static int finite_value(double value)
{
    return isfinite(value);
}

int64_t soboleva_modified_hyperbolic_tangent(const double *input, size_t input_length,
                                             double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 5 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    for (size_t i = 0; i < input_length; ++i) {
        if (!finite_value(input[i])) return -1;
    }

    const double count_value = input[0];
    if (count_value < MIN_SAMPLE_COUNT || count_value > MAX_SAMPLE_COUNT) return -1;
    const size_t count = (size_t)count_value;
    if (count_value != (double)count || input_length != 5 + count) return -1;

    const double a = input[1], b = input[2], c = input[3], d = input[4];
    if (a < -2.0 || a > 2.0 || b < -2.0 || b > 2.0 ||
        c < -2.0 || c > 2.0 || d < -2.0 || d > 2.0) return -1;
    for (size_t i = 0; i < count; ++i) {
        if (input[5 + i] < -20.0 || input[5 + i] > 20.0) return -1;
    }

    if (output == NULL || output_capacity < count) return -2;
    for (size_t i = 0; i < count; ++i) {
        const double x = input[5 + i];
        const double ax = a * x;
        const double neg_b_x = (-b) * x;
        const double cx = c * x;
        const double neg_d_x = (-d) * x;
        const double numerator = exp(ax) - exp(neg_b_x);
        const double denominator = exp(cx) + exp(neg_d_x);
        output[i] = numerator / denominator;
    }
    return (int64_t)count;
}
