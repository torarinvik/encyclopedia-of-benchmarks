#include <cstddef>
#include <cstdint>

extern "C" std::int64_t gray_to_decimal(const std::int64_t *values, std::size_t length) noexcept
{
    if (values == nullptr || length < 2 || length > 64) return -1;
    const std::int64_t bit_length = values[0];
    if (bit_length < 1 || bit_length > 63 || length != static_cast<std::size_t>(bit_length) + 1) return -1;

    std::int64_t prefix = 0;
    std::int64_t binary = 0;
    for (std::size_t index = 1; index < length; ++index) {
        const std::int64_t character = values[index];
        if (character != 48 && character != 49) return -1;
        prefix ^= character - 48;
        binary = binary * 2 + prefix;
    }
    return binary;
}
