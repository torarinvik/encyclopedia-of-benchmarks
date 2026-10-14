/* Enumerate phone keypad combinations into fixed-width concatenated output. */
#include <stddef.h>
#include <stdint.h>

static size_t letter_count(int64_t digit)
{
    return digit == 7 || digit == 9 ? 4 : 3;
}

static uint8_t letter_base(int64_t digit)
{
    static const uint8_t bases[] = {0, 0, 'a', 'd', 'g', 'j', 'm', 'p', 't', 'w'};
    return bases[digit];
}

static void expand(const int64_t *digits, size_t length, size_t index, uint8_t *output,
                   size_t output_offset, size_t combination_count)
{
    if (index == length) return;
    const size_t alternatives = letter_count(digits[index]);
    const size_t block_count = combination_count / alternatives;
    const uint8_t base = letter_base(digits[index]);
    for (size_t letter = 0; letter < alternatives; ++letter) {
        const size_t branch_offset = output_offset + letter * block_count * length;
        for (size_t row = 0; row < block_count; ++row)
            output[branch_offset + row * length + index] = (uint8_t)(base + letter);
        expand(digits, length, index + 1, output, branch_offset, block_count);
    }
}

int64_t letter_combinations_of_phone_number(const int64_t *digits, size_t length,
                                             uint8_t *output, size_t output_capacity)
{
    if (length == 0) return 0;
    if (length > 6 || digits == NULL) return -1;
    size_t count = 1;
    for (size_t index = 0; index < length; ++index) {
        if (digits[index] < 2 || digits[index] > 9) return -1;
        count *= letter_count(digits[index]);
    }
    const size_t required = count * length;
    if (output_capacity < required || output == NULL) return -2;
    expand(digits, length, 0, output, 0, count);
    return (int64_t)count;
}
