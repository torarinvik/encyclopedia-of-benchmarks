/* Decide binary divisibility by three with a three-state streaming DFA. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_BITS = 4096, MAX_INPUT_LENGTH = MAX_BITS + 2 };

int64_t binary_divisibility_by_three_dfa(const int64_t *input, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length == 0 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t bit_count = input[0];
    if (bit_count < 1 || bit_count > MAX_BITS || (size_t)bit_count + 1 != length)
        return -1;
    int remainder = 0;
    for (size_t index = 1; index < length; ++index) {
        if (input[index] != 0 && input[index] != 1) return -1;
        remainder = (2 * remainder + (int)input[index]) % 3;
    }
    if (output == NULL || output_capacity < 1) return -2;

    output[0] = (uint8_t)(remainder == 0);
    return 1;
}
