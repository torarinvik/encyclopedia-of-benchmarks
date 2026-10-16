/* Bounded callback adapter for the pinned Rust trapezoidal integrator. */
#include <stddef.h>
#include <stdint.h>

#define SCALE INT64_C(1000000)
#define MAX_ENDPOINT_MICRO INT64_C(1000000)
#define MAX_STEPS INT64_C(10000)
#define INVALID_RESULT (-1.0e300)

static double sample_value(int64_t function_id, double x) {
    if (function_id == 0) return x * x;
    return x * x * x;
}

double trapezoidal_integration(const int64_t *values, size_t length) {
    if (values == NULL || length != 4) return INVALID_RESULT;
    const int64_t start_micro = values[0], end_micro = values[1];
    const int64_t steps = values[2], function_id = values[3];
    if (start_micro < -MAX_ENDPOINT_MICRO || start_micro > MAX_ENDPOINT_MICRO ||
        end_micro < -MAX_ENDPOINT_MICRO || end_micro > MAX_ENDPOINT_MICRO ||
        steps < 1 || steps > MAX_STEPS || function_id < 0 || function_id > 1) return INVALID_RESULT;
    const double start = (double)start_micro / (double)SCALE;
    const double end = (double)end_micro / (double)SCALE;
    const double delta = (end - start) / (double)steps;
    double total = 0.0;
    for (int64_t index = 0; index < steps; ++index) {
        const double left = start + delta * (double)index;
        const double right = left + delta;
        const double midpoint = (sample_value(function_id, left) + sample_value(function_id, right)) * 0.5;
        total += midpoint * delta;
    }
    return total;
}
