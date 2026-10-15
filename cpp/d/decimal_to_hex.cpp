#include <cstddef>
#include <cstdint>

extern "C" std::int64_t decimal_to_hex(std::int64_t value, std::uint8_t *output, std::size_t capacity) noexcept {
    if (value < 0 || value > INT64_C(9007199254740991)) return -1;
    std::size_t width = 1;
    for (auto n = value; n >= 16; n /= 16) ++width;
    if (output == nullptr || capacity < width) return -2;
    std::size_t position = width;
    do {
        const auto digit = value % 16;
        output[--position] = static_cast<std::uint8_t>(digit < 10 ? '0' + digit : 'A' + digit - 10);
        value /= 16;
    } while (position > 0);
    return static_cast<std::int64_t>(width);
}
