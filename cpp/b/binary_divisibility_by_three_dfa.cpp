// Decide binary divisibility by three with a three-state streaming DFA.
#include <cstddef>
#include <cstdint>

extern "C" std::int64_t binary_divisibility_by_three_dfa(
    const std::int64_t *input, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (input == nullptr || length == 0 || length > 4098) return -1;
    const std::int64_t bit_count = input[0];
    if (bit_count < 1 || bit_count > 4096
            || static_cast<std::size_t>(bit_count) + 1 != length) return -1;
    int remainder = 0;
    for (std::size_t index = 1; index < length; ++index) {
        if (input[index] != 0 && input[index] != 1) return -1;
        remainder = (2 * remainder + static_cast<int>(input[index])) % 3;
    }
    if (output == nullptr || output_capacity < 1) return -2;

    output[0] = static_cast<std::uint8_t>(remainder == 0);
    return 1;
}
