#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_count = 18;
constexpr std::size_t max_input_length = 19;
constexpr std::size_t output_count = 18;
constexpr double pi = 3.14159265358979323846264338327950288;
}

extern "C" std::int64_t mibench_lame_mdct_long(const double* input,
                                                std::size_t input_length,
                                                double* output,
                                                std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length == 0 || input_length > max_input_length) return -1;
    for (std::size_t k = 0; k < input_length; ++k) {
        if (!std::isfinite(input[k]) || input[k] < -16.0 || input[k] > 16.0) return -1;
    }
    if (input_length != input_count) return -1;

    double staged[output_count];
    for (std::size_t m = 0; m < output_count; ++m) {
        double sum = 0.0;
        for (std::size_t k = 0; k < input_count; ++k) {
            const std::size_t offset = k < 9 ? 38 : 74;
            const double angle = pi * static_cast<double>(2 * m + 1) *
                static_cast<double>(4 * k + offset) / 144.0;
            sum += input[k] * std::cos(angle);
        }
        staged[m] = (4.0 / 36.0) * sum;
    }
    if (output == nullptr || output_capacity < output_count) return -2;
    for (std::size_t m = 0; m < output_count; ++m) output[m] = staged[m];
    return static_cast<std::int64_t>(output_count);
}
