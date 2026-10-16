// Selected entry in the Haskell complementary-filter scan trace.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t MAX_SAMPLES = 32; constexpr std::int64_t SCALE = 1'000'000; constexpr std::int64_t MAX_SIGNAL_MICRO = 1'000'000; constexpr double INVALID_RESULT = -1.0e300; }

extern "C" double comp_filt(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 6 || length > 68) return INVALID_RESULT;
    const auto alpha_ppm = values[0];
    const auto delta_t_micro = values[1];
    const auto count_value = values[2];
    const auto output_index_value = values[3];
    if (alpha_ppm < 0 || alpha_ppm > SCALE || delta_t_micro < 0 || delta_t_micro > SCALE ||
        count_value < 1 || count_value > MAX_SAMPLES || output_index_value < 0 || output_index_value > count_value)
        return INVALID_RESULT;
    const auto count = static_cast<std::size_t>(count_value);
    const auto output_index = static_cast<std::size_t>(output_index_value);
    if (length != 4 + 2 * count) return INVALID_RESULT;
    for (std::size_t i = 0; i < count; ++i) {
        const auto rate = values[4 + i];
        const auto reference = values[4 + count + i];
        if (rate < -MAX_SIGNAL_MICRO || rate > MAX_SIGNAL_MICRO ||
            reference < -MAX_SIGNAL_MICRO || reference > MAX_SIGNAL_MICRO) return INVALID_RESULT;
    }
    const double alpha = static_cast<double>(alpha_ppm) / static_cast<double>(SCALE);
    const double delta_t = static_cast<double>(delta_t_micro) / static_cast<double>(SCALE);
    double theta = static_cast<double>(values[4 + count]) / static_cast<double>(SCALE);
    for (std::size_t i = 0; i < output_index; ++i) {
        const double rate = static_cast<double>(values[4 + i]) / static_cast<double>(SCALE);
        const double reference = static_cast<double>(values[4 + count + i]) / static_cast<double>(SCALE);
        theta = alpha * (theta + rate * delta_t) + (1.0 - alpha) * reference;
    }
    return theta;
}
