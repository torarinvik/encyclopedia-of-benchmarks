#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t input_count = 18;
constexpr std::size_t max_input_length = 19;
constexpr std::size_t output_count = 36;
constexpr double pi = 3.14159265358979323846264338327950288;
}

extern "C" std::int64_t cbench_consumer_mad_imdct36(const double* input,
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
    for (std::size_t n = 0; n < output_count; ++n) {
        double sum = 0.0;
        for (std::size_t k = 0; k < input_count; ++k) {
            const double angle = pi * static_cast<double>(2 * n + 19) *
                static_cast<double>(2 * k + 1) / 72.0;
            sum += input[k] * std::cos(angle);
        }
        staged[n] = sum;
    }
    if (output == nullptr || output_capacity < output_count) return -2;
    for (std::size_t n = 0; n < output_count; ++n) output[n] = staged[n];
    return static_cast<std::int64_t>(output_count);
}
