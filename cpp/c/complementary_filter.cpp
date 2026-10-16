#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_samples = 32;
constexpr std::int64_t scale = 1'000'000;
constexpr std::int64_t max_signal_micro = 1'000'000;
constexpr double invalid_result = -1.0e300;
}

extern "C" double complementary_filter(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 2) return invalid_result;
    const auto coefficient_ppm = values[0];
    const auto sample_count_value = values[1];
    if (coefficient_ppm < 1 || coefficient_ppm >= scale || sample_count_value < 1 ||
        sample_count_value > max_samples) return invalid_result;
    const auto sample_count = static_cast<std::size_t>(sample_count_value);
    if (length != 2 + 3 * sample_count) return invalid_result;
    for (std::size_t sample = 0; sample < sample_count; ++sample) {
        const auto rate = values[2 + 3 * sample];
        const auto reference = values[3 + 3 * sample];
        const auto elapsed = values[4 + 3 * sample];
        if (rate < -max_signal_micro || rate > max_signal_micro ||
            reference < -max_signal_micro || reference > max_signal_micro || elapsed < 1 || elapsed > scale)
            return invalid_result;
    }
    const double coefficient = static_cast<double>(coefficient_ppm) / static_cast<double>(scale);
    double value = 0.0;
    for (std::size_t sample = 0; sample < sample_count; ++sample) {
        const double rate = static_cast<double>(values[2 + 3 * sample]) / static_cast<double>(scale);
        const double reference = static_cast<double>(values[3 + 3 * sample]) / static_cast<double>(scale);
        const double elapsed = static_cast<double>(values[4 + 3 * sample]) / static_cast<double>(scale);
        if (sample == 0) value = reference;
        else value = coefficient * (value + rate * elapsed) + (1.0 - coefficient) * reference;
    }
    return value;
}
