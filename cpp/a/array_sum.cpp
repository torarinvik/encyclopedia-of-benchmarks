// Sum a bounded array of nonnegative signed integers.
#include <cstddef>
#include <cstdint>

namespace { constexpr std::int64_t INVALID_RESULT = -1; }

extern "C" std::int64_t array_sum(const std::int64_t *values, std::size_t length) noexcept {
    if (values == nullptr || length < 1) return INVALID_RESULT;
    const auto count_value = values[0];
    if (count_value < 0 || count_value > 1024) return INVALID_RESULT;
    const auto count = static_cast<std::size_t>(count_value);
    if (length != count + 1) return INVALID_RESULT;
    std::int64_t sum = 0;
    for (std::size_t i = 0; i < count; ++i) {
        const auto value = values[i + 1];
        if (value < 0 || value > 1000000000) return INVALID_RESULT;
        sum += value;
    }
    return sum;
}
