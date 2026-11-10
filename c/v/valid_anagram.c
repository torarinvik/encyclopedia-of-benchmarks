/* Compare lowercase ASCII strings by their letter frequencies. */
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 1024
#define MAX_INPUT_LENGTH (2 + 2 * MAX_STRING_LENGTH)

int64_t valid_anagram(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const uint64_t first = (uint64_t)input[0];
    const uint64_t second = (uint64_t)input[1];
    if (first > MAX_STRING_LENGTH || second > MAX_STRING_LENGTH ||
        length != 2 + first + second) return -1;
    if (first != second) {
        for (size_t i = 2; i < length; ++i)
            if ((uint64_t)input[i] - 97 > 25) return -1;
        return 0;
    }

    uint16_t counts[26] = {0};
    const size_t count = (size_t)first;
    for (size_t i = 2; i < 2 + count; ++i) {
        const uint64_t left = (uint64_t)input[i] - 97;
        const uint64_t right = (uint64_t)input[i + count] - 97;
        if (left > 25 || right > 25) return -1;
        if (left != right) {
            ++counts[left];
            --counts[right];
        }
    }
    for (size_t slot = 0; slot < 26; ++slot)
        if (counts[slot] != 0) return 0;
    return 1;
}
