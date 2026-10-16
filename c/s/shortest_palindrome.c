/* Add the minimum prefix needed to make a printable ASCII string a palindrome. */
#include <stddef.h>
#include <stdint.h>

#define MAX_INPUT_LENGTH 64

int64_t shortest_palindrome(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (length > MAX_INPUT_LENGTH || (length > 0 && input == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (input[i] < 32 || input[i] > 126) return -1;
    if (length == 0) return 0;

    size_t suffix[64] = {0};
    for (size_t i = 1; i < length; ++i) {
        size_t matched = suffix[i - 1];
        while (matched > 0 && input[matched] != input[i]) matched = suffix[matched - 1];
        if (input[matched] == input[i]) ++matched;
        suffix[i] = matched;
    }

    size_t prefix_match = 0;
    for (size_t i = 0; i < length; ++i) {
        const int64_t reversed_value = input[length - 1 - i];
        while (prefix_match > 0 && reversed_value != input[prefix_match])
            prefix_match = suffix[prefix_match - 1];
        if (reversed_value == input[prefix_match]) ++prefix_match;
    }

    const size_t output_length = 2 * length - prefix_match;
    if (output == NULL || output_capacity < output_length) return -2;
    for (size_t i = 0; i < length; ++i)
        output[i] = (uint8_t)input[length - 1 - i];
    for (size_t i = prefix_match; i < length; ++i)
        output[length + i - prefix_match] = (uint8_t)input[i];
    return (int64_t)output_length;
}
