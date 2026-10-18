#include <math.h>
#include <stddef.h>
#include <stdint.h>

enum {
    MIN_RANDOM_POINTS = 1,
    MAX_RANDOM_POINTS = 64,
    MAX_INPUT_LENGTH = 130
};

static int finite_value(double value)
{
    return isfinite(value) != 0;
}

static int exact_sample_count(double value, size_t *count)
{
    if (!finite_value(value) || value < (double)MIN_RANDOM_POINTS ||
        value > (double)MAX_RANDOM_POINTS || value != trunc(value)) return 0;
    *count = (size_t)value;
    return 1;
}

static double rounded_divide(double numerator, double denominator)
{
    volatile double result = numerator / denominator;
    return result;
}

static double rounded_multiply(double left, double right)
{
    volatile double result = left * right;
    return result;
}

static int allowed_coordinate(double value)
{
    return value == 0.0 || value == 0.25 || value == 0.5 || value == 0.75;
}

int64_t montecarlopi(const double *values, size_t length,
                     double *output, size_t output_capacity)
{
    if (values == NULL || length < 3u || length > MAX_INPUT_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!finite_value(values[index])) return -1;

    size_t random_points;
    if (!exact_sample_count(values[0], &random_points) ||
        length != 1u + 2u * random_points) return -1;

    size_t inside = 0u;
    for (size_t index = 0u; index < random_points; ++index) {
        const double x = values[1u + 2u * index];
        const double y = values[2u + 2u * index];
        if (!allowed_coordinate(x) || !allowed_coordinate(y)) return -1;
        const double x_squared = rounded_multiply(x, x);
        const double y_squared = rounded_multiply(y, y);
        const double squared_radius = x_squared + y_squared;
        if (squared_radius <= 1.0) ++inside;
    }

    const double fraction = rounded_divide((double)inside, (double)random_points);
    const double estimate = rounded_multiply(fraction, 4.0);
    if (!finite_value(estimate)) return -1;

    if (output == NULL || output_capacity < 1u) return -2;
    output[0] = estimate;
    return 1;
}
