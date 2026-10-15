#include <math.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0)
#define MAX_INTERVALS 128

static double sample(int32_t function_id, double x)
{
    switch (function_id) {
        case 0: return sqrt(x) + log(x);
        case 1: return exp(-x) * (4.0 - pow(x, 2.0));
        case 2: return sqrt(2.0 * pow(x, 3.0) + 3.0);
        default: return x + log(2.0 * x + 1.0);
    }
}

double composite_simpson_rule(double intervals_input, double function_id_input)
{
    if (!isfinite(intervals_input) || !isfinite(function_id_input) ||
        intervals_input < 2.0 || intervals_input > MAX_INTERVALS ||
        floor(intervals_input) != intervals_input ||
        function_id_input < 0.0 || function_id_input > 3.0 ||
        floor(function_id_input) != function_id_input) return INVALID_RESULT;

    const int32_t intervals = (int32_t)intervals_input;
    if (intervals % 2 != 0) return INVALID_RESULT;
    const int32_t function_id = (int32_t)function_id_input;
    const double h = 2.0 / (double)intervals;
    double x = 1.0;
    double sum = 0.0;
    for (int32_t i = 0; i <= intervals; ++i) {
        const double y = sample(function_id, x);
        const double weight = (i == 0 || i == intervals) ? 1.0 : ((i % 2) ? 4.0 : 2.0);
        sum += weight * y;
        x += h;
    }
    return sum * (h / 3.0);
}
