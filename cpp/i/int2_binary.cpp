// Encode the C# uint overload as exactly 32 ASCII binary digits.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t int2_binary(std::int64_t value, std::uint8_t *output,
                                    std::size_t output_capacity) noexcept
{
    if (value < 0 || static_cast<std::uint64_t>(value) > UINT32_MAX) return -1;
    if (output == nullptr || output_capacity < 32) return -2;

    std::uint32_t remaining = static_cast<std::uint32_t>(value);
    std::uint32_t most_significant_bit = UINT32_C(0x80000000);
    for (std::size_t i = 0; i < 32; ++i) {
        if (remaining >= most_significant_bit) {
            output[i] = static_cast<std::uint8_t>('1');
            remaining -= most_significant_bit;
        } else {
            output[i] = static_cast<std::uint8_t>('0');
        }
        most_significant_bit /= 2;
    }
    return 32;
}
