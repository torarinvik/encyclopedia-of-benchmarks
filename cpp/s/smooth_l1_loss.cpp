#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_COUNT = 256;
constexpr std::int64_t MAX_PARSED_COUNT = 257;
constexpr std::int64_t MAX_SAMPLE = 1000000;
constexpr std::size_t MAX_INPUT_LENGTH = 515;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double smooth_l1_loss(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1 || length > MAX_INPUT_LENGTH) return INVALID_RESULT;
    const std::int64_t count_value = values[0];
    if (count_value < 0 || count_value > MAX_PARSED_COUNT) return INVALID_RESULT;
    if (length != static_cast<std::size_t>(1 + 2 * count_value) ||
        count_value == 0 || count_value > MAX_COUNT) return INVALID_RESULT;
    const std::size_t count = static_cast<std::size_t>(count_value);
    for (std::size_t index = 0; index < count * 2; ++index)
        if (values[1 + index] < -MAX_SAMPLE || values[1 + index] > MAX_SAMPLE) return INVALID_RESULT;
    double total = 0.0;
    for (std::size_t index = 0; index < count; ++index) {
        const double difference = static_cast<double>(values[1 + index]) / 1000000.0 -
                                  static_cast<double>(values[1 + count + index]) / 1000000.0;
        const double residual = difference < 0.0 ? -difference : difference;
        if (residual < 1.0) total += 0.5 * residual * residual / 1.0; else total += residual - 0.5;
    }
    return total / static_cast<double>(count);
}
