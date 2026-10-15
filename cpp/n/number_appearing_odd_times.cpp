// XOR-fold an int32 array to find its unique odd-frequency value.
#include <cstddef>
#include <cstdint>

namespace {
constexpr std::size_t max_length = 4096;
constexpr std::int64_t invalid_result = -2147483649LL;
}

extern "C" std::int64_t number_appearing_odd_times(const std::int64_t *values, std::size_t length) noexcept
{
    if (length == 0 || length > max_length || values == nullptr) return invalid_result;
    std::int32_t result = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < -2147483648LL || values[index] > 2147483647LL) return invalid_result;
        result ^= static_cast<std::int32_t>(values[index]);
    }
    return result;
}
