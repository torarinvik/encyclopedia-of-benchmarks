#include <cstddef>
#include <cstdint>

namespace {
constexpr std::int64_t MAX_VALUE = 1073741823;
}

extern "C" std::int64_t non_repeating_element(const std::int64_t *values,
                                               std::size_t length) noexcept
{
    if (length < 2 || length > 64 || (length & 1u) != 0) return -1;
    std::int32_t xor_result = 0;
    for (std::size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > MAX_VALUE) return -1;
        xor_result ^= static_cast<std::int32_t>(values[index]);
    }
    const std::int32_t rightmost_set_bit = xor_result & -xor_result;
    std::int32_t num1 = 0;
    std::int32_t num2 = 0;
    for (std::size_t index = 0; index < length; ++index) {
        const auto value = static_cast<std::int32_t>(values[index]);
        if ((value & rightmost_set_bit) != 0) num1 ^= value;
        else num2 ^= value;
    }
    return (static_cast<std::int64_t>(num1) << 32) | static_cast<std::uint32_t>(num2);
}
