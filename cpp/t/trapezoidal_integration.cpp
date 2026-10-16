/* Bounded callback adapter for the pinned Rust trapezoidal integrator. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t SCALE = 1000000;
constexpr std::int64_t MAX_ENDPOINT_MICRO = 1000000;
constexpr std::int64_t MAX_STEPS = 10000;
constexpr double INVALID_RESULT = -1.0e300;

double sample_value(std::int64_t function_id, double x) {
    if (function_id == 0) return x * x;
    return x * x * x;
}
}

extern "C" double trapezoidal_integration(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length != 4) return INVALID_RESULT;
    const std::int64_t start_micro = values[0], end_micro = values[1];
    const std::int64_t steps = values[2], function_id = values[3];
    if (start_micro < -MAX_ENDPOINT_MICRO || start_micro > MAX_ENDPOINT_MICRO ||
        end_micro < -MAX_ENDPOINT_MICRO || end_micro > MAX_ENDPOINT_MICRO ||
        steps < 1 || steps > MAX_STEPS || function_id < 0 || function_id > 1) return INVALID_RESULT;
    const double start = static_cast<double>(start_micro) / static_cast<double>(SCALE);
    const double end = static_cast<double>(end_micro) / static_cast<double>(SCALE);
    const double delta = (end - start) / static_cast<double>(steps);
    double total = 0.0;
    for (std::int64_t index = 0; index < steps; ++index) {
        const double left = start + delta * static_cast<double>(index);
        const double right = left + delta;
        const double midpoint = (sample_value(function_id, left) + sample_value(function_id, right)) * 0.5;
        total += midpoint * delta;
    }
    return total;
}
