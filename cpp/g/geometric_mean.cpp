#include <cmath>
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_LENGTH = 6;
constexpr std::int64_t MAX_ABS_VALUE = 100;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double geometric_mean(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length == 0 || length > MAX_LENGTH) return INVALID_RESULT;
    std::int64_t product = 1;
    for (std::size_t i = 0; i < length; ++i) {
        if (values[i] < -MAX_ABS_VALUE || values[i] > MAX_ABS_VALUE) return INVALID_RESULT;
        product *= values[i];
    }
    if (product < 0 && length % 2 == 0) return INVALID_RESULT;
    double root = std::pow(std::abs(static_cast<double>(product)), 1.0 / static_cast<double>(length));
    const double rounded = std::floor(root + 0.5);
    std::int64_t rounded_power = 1;
    for (std::size_t i = 0; i < length; ++i) rounded_power *= static_cast<std::int64_t>(rounded);
    if ((product >= 0 && rounded_power == product)
        || (product < 0 && length % 2 == 1 && -rounded_power == product)) root = rounded;
    if (product < 0) root = -root;
    return root;
}
