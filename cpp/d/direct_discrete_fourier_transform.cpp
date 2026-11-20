#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + 2 * max_n + 1;
constexpr double tau = 6.283185307179586476925286766559;
}

extern "C" std::int64_t direct_discrete_fourier_transform(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 2 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i)
        if (!std::isfinite(input[i])) return -1;
    const double n_value = input[0];
    if (n_value < 1.0 || n_value > static_cast<double>(max_n)
        || std::floor(n_value) != n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if (input_length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;

    const std::size_t needed = 2 * n;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t k = 0; k < n; ++k) {
        double real_sum = 0.0;
        double imag_sum = 0.0;
        for (std::size_t j = 0; j < n; ++j) {
            const double angle = -tau * static_cast<double>(j) * static_cast<double>(k)
                               / static_cast<double>(n);
            const double cosine = std::cos(angle);
            const double sine = std::sin(angle);
            const double sample_real = input[1 + 2 * j];
            const double sample_imag = input[2 + 2 * j];
            real_sum += sample_real * cosine + sample_imag * sine;
            imag_sum += sample_imag * cosine - sample_real * sine;
        }
        output[2 * k] = real_sum;
        output[2 * k + 1] = imag_sum;
    }
    return static_cast<std::int64_t>(needed);
}

