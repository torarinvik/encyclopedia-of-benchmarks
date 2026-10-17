#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t max_sample_count = 64;
constexpr std::size_t max_input_length = 68;
constexpr std::int64_t min_sample_micro = -1'000'000;
constexpr std::int64_t max_sample_micro = 1'000'000;
constexpr double invalid_result = -1.0e300;
}

extern "C" double laplace_transformation(const std::int64_t *input, std::size_t length) noexcept {
    if (input == nullptr || length < 3 || length > max_input_length) return invalid_result;
    const auto sample_count_value = input[0];
    const auto s_milli = input[1];
    const auto dt_micro = input[2];
    if (sample_count_value < 1 || sample_count_value > max_sample_count) return invalid_result;
    const auto sample_count = static_cast<std::size_t>(sample_count_value);
    if (length != sample_count + 3 || s_milli < 0 || s_milli > 1000 ||
        dt_micro < 1 || dt_micro > 1'000'000) return invalid_result;

    double samples[64];
    for (std::size_t index = 0; index < sample_count; ++index) {
        const auto sample = input[3 + index];
        if (sample < min_sample_micro || sample > max_sample_micro) return invalid_result;
        samples[index] = static_cast<double>(sample) / 1'000'000.0;
    }
    if (sample_count == 1) return 0.0;

    const double s_value = static_cast<double>(s_milli) / 1000.0;
    const double delta_t = static_cast<double>(dt_micro) / 1'000'000.0;
    const double stop = static_cast<double>(sample_count - 1) * delta_t;
    const double step = stop / static_cast<double>(sample_count - 1);
    double integrand[64];
    for (std::size_t index = 0; index < sample_count; ++index) {
        const double time = index == sample_count - 1 ? stop : static_cast<double>(index) * step;
        integrand[index] = samples[index] * std::exp(-s_value * time);
    }

    double result = 0.0;
    for (std::size_t index = 0; index + 1 < sample_count; ++index)
        result += (delta_t * (integrand[index] + integrand[index + 1])) / 2.0;
    return result;
}
