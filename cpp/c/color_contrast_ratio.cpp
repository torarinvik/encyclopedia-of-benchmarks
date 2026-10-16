#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr double invalid_result = -1.0e300;

double component(std::int64_t channel) noexcept {
    const double srgb = static_cast<double>(channel) / 255.0;
    if (srgb <= 0.03928) return srgb / 12.92;
    return std::pow((srgb + 0.055) / 1.055, 2.4);
}

double luminance(std::int64_t red, std::int64_t green, std::int64_t blue) noexcept {
    return 0.2126 * component(red) + 0.7152 * component(green) + 0.0722 * component(blue);
}
}

extern "C" double color_contrast_ratio(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length != 6) return invalid_result;
    for (std::size_t i = 0; i < 6; ++i) {
        if (values[i] < 0 || values[i] > 255) return invalid_result;
    }
    const double first = luminance(values[0], values[1], values[2]);
    const double second = luminance(values[3], values[4], values[5]);
    if (first > second) return (first + 0.05) / (second + 0.05);
    return (second + 0.05) / (first + 0.05);
}
