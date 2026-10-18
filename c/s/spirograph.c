/* Generate bounded, interleaved spirograph coordinates. */
#include <math.h>
#include <stddef.h>
#include <stdint.h>

#define MAX_POINTS 32
#define MAX_PARSEABLE_INPUT_LENGTH 5
#define MAX_OUTPUT_ELEMENTS (2 * MAX_POINTS)

static int exact_point_count(double value, size_t *point_count)
{
    if (!isfinite(value) || value < 1.0 || value > (double)MAX_POINTS) return 0;
    const int converted = (int)value;
    if ((double)converted != value) return 0;
    *point_count = (size_t)converted;
    return 1;
}

int64_t spirograph(const double *input, size_t input_length,
                   double *output, size_t output_capacity)
{
    if (input == NULL || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH ||
        input_length != 4) return -1;

    size_t point_count;
    if (!exact_point_count(input[0], &point_count)) return -1;
    const double marker_ratio = input[1];
    const double inner_ratio = input[2];
    const double rotations = input[3];
    if (!isfinite(marker_ratio) || marker_ratio < 0.0 || marker_ratio > 1.0 ||
        !isfinite(inner_ratio) || inner_ratio < 0.25 || inner_ratio > 0.75 ||
        !isfinite(rotations) || rotations < 0.0 || rotations > 10.0) return -1;

    const double pi = 3.141592653589793238462643383279502884;
    const double delta = rotations * 2.0 * pi / (double)point_count;
    const double outer_ratio = 1.0 - inner_ratio;
    const double marker_radius = marker_ratio * inner_ratio;
    double staged[MAX_OUTPUT_ELEMENTS];
    for (size_t index = 0; index < point_count; ++index) {
        const double t = delta * (double)index;
        const double inner_angle = outer_ratio * t / inner_ratio;
        const double x = outer_ratio * cos(t) + marker_radius * cos(inner_angle);
        const double y = outer_ratio * sin(t) - marker_radius * sin(inner_angle);
        if (!isfinite(x) || !isfinite(y)) return -1;
        staged[2 * index] = x;
        staged[2 * index + 1] = y;
    }

    const size_t output_length = 2 * point_count;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t index = 0; index < output_length; ++index) output[index] = staged[index];
    return (int64_t)output_length;
}
