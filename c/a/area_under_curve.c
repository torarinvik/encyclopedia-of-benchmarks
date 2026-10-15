/* Composite trapezoidal integration for three bounded sample functions. */
#include <stddef.h>
#include <stdint.h>

#define MAX_STEPS 10000
#define MAX_COORD_MILLI 100000
#define OUTPUT_SCALE 1000000.0

static double sample_value(int64_t function_id, double x)
{
    if (function_id == 0) return 5.0;
    if (function_id == 1) return x;
    return x * x;
}

int64_t area_under_curve(const int64_t *input, size_t length)
{
    if (input == NULL || length != 4) return -1;
    const int64_t function_id = input[0];
    const int64_t start_milli = input[1];
    const int64_t end_milli = input[2];
    const int64_t steps = input[3];
    if (function_id < 0 || function_id > 2 || start_milli < 0 || start_milli > MAX_COORD_MILLI ||
        end_milli < 0 || end_milli > MAX_COORD_MILLI || steps < 1 || steps > MAX_STEPS) return -1;

    const int64_t low_milli = start_milli < end_milli ? start_milli : end_milli;
    const int64_t high_milli = start_milli < end_milli ? end_milli : start_milli;
    const double start = (double)low_milli / 1000.0;
    const double end = (double)high_milli / 1000.0;
    const double width = (end - start) / (double)steps;
    double x1 = start;
    double y1 = sample_value(function_id, x1);
    double area = 0.0;
    for (int64_t index = 0; index < steps; ++index) {
        const double x2 = x1 + width;
        const double y2 = sample_value(function_id, x2);
        area += (y1 + y2) * width * 0.5;
        x1 = x2;
        y1 = y2;
    }
    return (int64_t)(area * OUTPUT_SCALE + 0.5);
}
