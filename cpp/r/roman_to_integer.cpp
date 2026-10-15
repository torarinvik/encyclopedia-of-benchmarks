// Decode canonical uppercase Roman numerals in the range 1 through 3,999.
#include <cstddef>
#include <cstdint>

static std::int64_t decode_digit(const std::int64_t *symbols, std::size_t length, std::size_t position,
                                std::int64_t one, std::int64_t five, std::int64_t ten)
{
    if (position >= length) return 0;
    if (symbols[position] == one) {
        if (position + 1 < length) {
            if (symbols[position + 1] == ten) return 9 * 16 + 2;
            if (symbols[position + 1] == five) return 4 * 16 + 2;
        }
        std::size_t count = 0;
        while (position + count < length && symbols[position + count] == one && count < 3) ++count;
        if (position + count < length && symbols[position + count] == one) return -1;
        return static_cast<std::int64_t>(count * 16 + count);
    }
    if (symbols[position] == five) {
        std::size_t count = 0;
        while (position + 1 + count < length && symbols[position + 1 + count] == one && count < 3) ++count;
        if (position + 1 + count < length && symbols[position + 1 + count] == one) return -1;
        return static_cast<std::int64_t>((5 + count) * 16 + 1 + count);
    }
    return 0;
}

extern "C" std::int64_t roman_to_integer(const std::int64_t *symbols, std::size_t length)
{
    if (length == 0 || length > 15) return -1;
    for (std::size_t index = 0; index < length; ++index) {
        const auto symbol = symbols[index];
        if (symbol != 'I' && symbol != 'V' && symbol != 'X' && symbol != 'L' &&
            symbol != 'C' && symbol != 'D' && symbol != 'M') return -1;
    }
    std::size_t position = 0;
    std::size_t thousands = 0;
    while (position < length && symbols[position] == 'M' && thousands < 3) {
        ++position;
        ++thousands;
    }
    if (position < length && symbols[position] == 'M') return -1;
    const auto hundreds = decode_digit(symbols, length, position, 'C', 'D', 'M');
    if (hundreds < 0) return -1;
    position += static_cast<std::size_t>(hundreds & 15);
    const auto tens = decode_digit(symbols, length, position, 'X', 'L', 'C');
    if (tens < 0) return -1;
    position += static_cast<std::size_t>(tens & 15);
    const auto ones = decode_digit(symbols, length, position, 'I', 'V', 'X');
    if (ones < 0) return -1;
    position += static_cast<std::size_t>(ones & 15);
    if (position != length) return -1;
    const auto value = static_cast<std::int64_t>(thousands) * 1000 + (hundreds >> 4) * 100 +
        (tens >> 4) * 10 + (ones >> 4);
    return value >= 1 && value <= 3999 ? value : -1;
}
