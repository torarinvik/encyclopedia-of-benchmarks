#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t output_length = 4;

std::int64_t round_ties_to_even(double value) {
    const double lower = std::floor(value);
    const double fraction = value - lower;
    const auto base = static_cast<std::int64_t>(lower);
    if (fraction < 0.5) return base;
    if (fraction > 0.5) return base + 1;
    return (base & 1) == 0 ? base : base + 1;
}
}

extern "C" std::int64_t rgb_cmyk_conversion(const std::int64_t *input, std::size_t length,
                                             std::uint8_t *output, std::size_t capacity) noexcept {
    if (input == nullptr || length != 3) return -1;
    for (std::size_t i = 0; i < 3; ++i) if (input[i] < 0 || input[i] > 255) return -1;
    if (output == nullptr || capacity < output_length) return -2;
    const double red = static_cast<double>(input[0]) / 255.0;
    const double green = static_cast<double>(input[1]) / 255.0;
    const double blue = static_cast<double>(input[2]) / 255.0;
    double maximum = red;
    if (green > maximum) maximum = green;
    if (blue > maximum) maximum = blue;
    const double key = 1.0 - maximum;
    if (key == 1.0) { output[0] = output[1] = output[2] = 0; output[3] = 100; return output_length; }
    const double denominator = 1.0 - key;
    output[0] = static_cast<std::uint8_t>(round_ties_to_even(100.0 * (1.0 - red - key) / denominator));
    output[1] = static_cast<std::uint8_t>(round_ties_to_even(100.0 * (1.0 - green - key) / denominator));
    output[2] = static_cast<std::uint8_t>(round_ties_to_even(100.0 * (1.0 - blue - key) / denominator));
    output[3] = static_cast<std::uint8_t>(round_ties_to_even(100.0 * key));
    return output_length;
}
