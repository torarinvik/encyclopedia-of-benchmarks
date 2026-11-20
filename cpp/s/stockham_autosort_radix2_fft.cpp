#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_n = 64;
constexpr std::size_t max_input_length = 1 + 2 * max_n + 1;
constexpr std::size_t max_scalars = 2 * max_n;
constexpr double tau = 6.283185307179586476925286766559;

void stockham_stage(const double *source, double *destination,
                    std::size_t n, std::size_t stride) noexcept
{
    for (std::size_t j = 0; j < n / 2; ++j) {
        const std::size_t column = j % stride;
        const std::size_t group = j / stride;
        const std::size_t base = group * 2 * stride + column;
        const double angle = -tau * static_cast<double>(column) / static_cast<double>(2 * stride);
        const double cosine = std::cos(angle), sine = std::sin(angle);
        const std::size_t left = 2 * j, right = 2 * (j + n / 2);
        const double product_real = cosine * source[right] - sine * source[right + 1];
        const double product_imag = cosine * source[right + 1] + sine * source[right];
        const double first_real = source[left], first_imag = source[left + 1];
        const std::size_t out_left = 2 * base, out_right = 2 * (base + stride);
        destination[out_left] = first_real + product_real;
        destination[out_left + 1] = first_imag + product_imag;
        destination[out_right] = first_real - product_real;
        destination[out_right + 1] = first_imag - product_imag;
    }
}
}

extern "C" std::int64_t stockham_autosort_radix2_fft(
    const double *input, std::size_t input_length,
    double *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || input_length < 3 || input_length > max_input_length) return -1;
    for (std::size_t i = 0; i < input_length; ++i) if (!std::isfinite(input[i])) return -1;
    const double n_value = input[0];
    if (n_value < 1.0 || n_value > static_cast<double>(max_n)
        || std::floor(n_value) != n_value) return -1;
    const auto n = static_cast<std::size_t>(n_value);
    if ((n & (n - 1)) != 0 || input_length != 1 + 2 * n) return -1;
    for (std::size_t i = 0; i < 2 * n; ++i)
        if (input[i + 1] < -8.0 || input[i + 1] > 8.0) return -1;

    double first[max_scalars]{};
    double second[max_scalars]{};
    for (std::size_t i = 0; i < 2 * n; ++i) first[i] = input[i + 1];
    double *source = first;
    double *destination = second;
    for (std::size_t stride = 1; stride < n; stride *= 2) {
        stockham_stage(source, destination, n, stride);
        double *old_source = source;
        source = destination;
        destination = old_source;
    }

    const std::size_t needed = 2 * n;
    if (output == nullptr || output_capacity < needed) return -2;
    for (std::size_t i = 0; i < needed; ++i) output[i] = source[i];
    return static_cast<std::int64_t>(needed);
}
