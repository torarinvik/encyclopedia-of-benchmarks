#include <cstddef>
#include <cstdint>

namespace {
int hex_value(std::int64_t value)
{
    if (value >= '0' && value <= '9') return static_cast<int>(value - '0');
    if (value >= 'A' && value <= 'F') return static_cast<int>(value - 'A' + 10);
    if (value >= 'a' && value <= 'f') return static_cast<int>(value - 'a' + 10);
    return -1;
}
}

extern "C" std::int64_t hex_to_binary(const std::int64_t *values, std::size_t length,
                                      std::uint8_t *output, std::size_t capacity)
{
    if (length > 256 || (length != 0 && values == nullptr)) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        if (hex_value(values[index]) < 0) return -1;
    }

    const auto required = length * 4;
    if (output == nullptr || capacity < required) return -2;
    for (std::size_t index = 0; index < length; ++index) {
        const int digit = hex_value(values[index]);
        for (std::size_t bit = 0; bit < 4; ++bit) {
            output[index * 4 + bit] = static_cast<std::uint8_t>(((digit >> (3 - bit)) & 1) ? '1' : '0');
        }
    }
    return static_cast<std::int64_t>(required);
}
