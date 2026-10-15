/* Convert a uint16 value to lowercase digits in a base from 2 through 16. */
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t int_to_string(std::int64_t packed, std::uint8_t *output,
                                       std::size_t output_capacity) noexcept {
    if (packed < 0) return -1;
    const auto value = packed / 15;
    const auto base = packed % 15 + 2;
    if (value > 65535) return -1;
    constexpr char symbols[] = "0123456789abcdef";
    std::uint8_t digits[16];
    std::size_t count = 0;
    auto remaining = value;
    do {
        digits[count++] = static_cast<std::uint8_t>(symbols[remaining % base]);
        remaining /= base;
    } while (remaining != 0);
    const auto required = count + 1;
    if (output == nullptr || output_capacity < required) return -2;
    for (std::size_t index = 0; index < count; ++index) output[index] = digits[count - index - 1];
    output[count] = 0;
    return static_cast<std::int64_t>(required);
}
