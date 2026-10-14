/* Enumerate phone keypad combinations into fixed-width concatenated output. */
#include <cstddef>
#include <cstdint>

static std::size_t letter_count(std::int64_t digit)
{
    return digit == 7 || digit == 9 ? 4 : 3;
}

static std::uint8_t letter_base(std::int64_t digit)
{
    static constexpr std::uint8_t bases[] = {0, 0, 'a', 'd', 'g', 'j', 'm', 'p', 't', 'w'};
    return bases[digit];
}

static void expand(const std::int64_t *digits, std::size_t length, std::size_t index,
                   std::uint8_t *output, std::size_t output_offset,
                   std::size_t combination_count)
{
    if (index == length) return;
    const auto alternatives = letter_count(digits[index]);
    const auto block_count = combination_count / alternatives;
    const auto base = letter_base(digits[index]);
    for (std::size_t letter = 0; letter < alternatives; ++letter) {
        const auto branch_offset = output_offset + letter * block_count * length;
        for (std::size_t row = 0; row < block_count; ++row)
            output[branch_offset + row * length + index] = static_cast<std::uint8_t>(base + letter);
        expand(digits, length, index + 1, output, branch_offset, block_count);
    }
}

extern "C" std::int64_t letter_combinations_of_phone_number(
    const std::int64_t *digits, std::size_t length,
    std::uint8_t *output, std::size_t output_capacity) noexcept
{
    if (length == 0) return 0;
    if (length > 6 || digits == nullptr) return -1;
    std::size_t count = 1;
    for (std::size_t index = 0; index < length; ++index) {
        if (digits[index] < 2 || digits[index] > 9) return -1;
        count *= letter_count(digits[index]);
    }
    const auto required = count * length;
    if (output_capacity < required || output == nullptr) return -2;
    expand(digits, length, 0, output, 0, count);
    return static_cast<std::int64_t>(count);
}
