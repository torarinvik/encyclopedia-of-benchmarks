#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t MAX_INPUT_LENGTH = 4096;
constexpr std::int64_t MAX_ABS_VALUE = 1'000'000'000;
constexpr double INVALID_RESULT = -1.0e300;
}

extern "C" double average(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > MAX_INPUT_LENGTH || values == nullptr) return INVALID_RESULT;
    std::int64_t sum = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const std::int64_t value = values[index];
        if (value < -MAX_ABS_VALUE || value > MAX_ABS_VALUE) return INVALID_RESULT;
        sum += value;
    }
    return static_cast<double>(sum) / static_cast<double>(length);
}
