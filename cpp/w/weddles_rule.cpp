/* Fixed-point sample adapter for the pinned Python Weddle-rule quadrature. */
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_PANELS = 64;
constexpr std::int64_t MAX_STEP_NANOUNITS = 1000000000;
constexpr std::int64_t MAX_SAMPLE_MICRO = 1000000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double weddles_rule(const std::int64_t *values, std::size_t length) {
    if (values == nullptr || length < 9 || length > 387) return INVALID_RESULT;
    const std::int64_t panels = values[0];
    const std::int64_t step_nanounits = values[1];
    if (panels < 1 || panels > MAX_PANELS || length != static_cast<std::size_t>(6 * panels + 3) ||
        step_nanounits < -MAX_STEP_NANOUNITS || step_nanounits > MAX_STEP_NANOUNITS) return INVALID_RESULT;

    const std::size_t sample_count = static_cast<std::size_t>(6 * panels + 1);
    double weighted_sum = 0.0;
    for (std::size_t index = 1; index + 1 < sample_count; ++index) {
        const std::int64_t sample_micro = values[index + 2];
        if (sample_micro < -MAX_SAMPLE_MICRO || sample_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
        std::int64_t weight;
        if (index % 2 == 0 && index % 3 != 0) weight = 1;
        else if (index % 2 != 0 && index % 3 != 0) weight = 5;
        else if (index % 6 == 0) weight = 2;
        else weight = 6;
        weighted_sum += static_cast<double>(weight) * (static_cast<double>(sample_micro) / 1000000.0);
    }
    const std::int64_t first_micro = values[2];
    const std::int64_t last_micro = values[sample_count + 1];
    if (first_micro < -MAX_SAMPLE_MICRO || first_micro > MAX_SAMPLE_MICRO ||
        last_micro < -MAX_SAMPLE_MICRO || last_micro > MAX_SAMPLE_MICRO) return INVALID_RESULT;
    const double step_size = static_cast<double>(step_nanounits) / 1000000000.0;
    return 0.3 * step_size * (weighted_sum + static_cast<double>(first_micro) / 1000000.0 +
                              static_cast<double>(last_micro) / 1000000.0);
}
