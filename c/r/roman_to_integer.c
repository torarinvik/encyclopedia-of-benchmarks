/* Decode canonical uppercase Roman numerals in the range 1 through 3,999. */
#include <stddef.h>
#include <stdint.h>

static int64_t decode_digit(const int64_t *symbols, size_t length, size_t position,
                            int64_t one, int64_t five, int64_t ten)
{
    if (position >= length) return 0;
    if (symbols[position] == one) {
        if (position + 1 < length) {
            if (symbols[position + 1] == ten) return 9 * 16 + 2;
            if (symbols[position + 1] == five) return 4 * 16 + 2;
        }
        size_t count = 0;
        while (position + count < length && symbols[position + count] == one && count < 3) ++count;
        if (position + count < length && symbols[position + count] == one) return -1;
        return (int64_t)(count * 16 + count);
    }
    if (symbols[position] == five) {
        size_t count = 0;
        while (position + 1 + count < length && symbols[position + 1 + count] == one && count < 3) ++count;
        if (position + 1 + count < length && symbols[position + 1 + count] == one) return -1;
        return (int64_t)((5 + count) * 16 + 1 + count);
    }
    return 0;
}

int64_t roman_to_integer(const int64_t *symbols, size_t length)
{
    if (length == 0 || length > 15) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (symbols[index] != 'I' && symbols[index] != 'V' && symbols[index] != 'X' &&
            symbols[index] != 'L' && symbols[index] != 'C' && symbols[index] != 'D' &&
            symbols[index] != 'M') return -1;
    }
    size_t position = 0;
    size_t thousands = 0;
    while (position < length && symbols[position] == 'M' && thousands < 3) {
        ++position;
        ++thousands;
    }
    if (position < length && symbols[position] == 'M') return -1;
    const int64_t hundreds = decode_digit(symbols, length, position, 'C', 'D', 'M');
    if (hundreds < 0) return -1;
    position += (size_t)(hundreds & 15);
    const int64_t tens = decode_digit(symbols, length, position, 'X', 'L', 'C');
    if (tens < 0) return -1;
    position += (size_t)(tens & 15);
    const int64_t ones = decode_digit(symbols, length, position, 'I', 'V', 'X');
    if (ones < 0) return -1;
    position += (size_t)(ones & 15);
    if (position != length) return -1;
    const int64_t value = (int64_t)thousands * 1000 + (hundreds >> 4) * 100 +
        (tens >> 4) * 10 + (ones >> 4);
    return value >= 1 && value <= 3999 ? value : -1;
}
