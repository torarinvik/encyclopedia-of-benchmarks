#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_precision = 12;

double sqrt_10005() noexcept
{
    double root = 100.0;
    for (int iteration = 0; iteration < 8; ++iteration)
        root = 0.5 * (root + 10005.0 / root);
    return root;
}
}

extern "C" std::int64_t chudnovsky_algorithm(const std::int64_t *values, std::size_t length,
                                              std::uint8_t *output, std::size_t capacity) noexcept
{
    if (values == nullptr || length != 1 || values[0] < 1 || values[0] > static_cast<std::int64_t>(max_precision)) return -1;
    const auto precision = static_cast<std::size_t>(values[0]);
    const auto output_length = precision == 1 ? 0 : precision;
    if (capacity < output_length || (output_length > 0 && output == nullptr)) return -2;
    if (precision == 1) return 0;

    const double pi = (426880.0 * sqrt_10005()) / 13591409.0;
    auto fraction = pi - 3.0;
    output[0] = '3';
    output[1] = '.';
    for (std::size_t digit = 0; digit < precision - 2; ++digit) {
        fraction *= 10.0;
        const auto next_digit = static_cast<int>(fraction);
        output[2 + digit] = static_cast<std::uint8_t>('0' + next_digit);
        fraction -= static_cast<double>(next_digit);
    }
    return static_cast<std::int64_t>(output_length);
}
