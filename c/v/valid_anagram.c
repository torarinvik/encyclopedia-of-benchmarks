/* Compare lowercase ASCII strings by their letter frequencies. */
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 1024
#define MAX_INPUT_LENGTH (2 + 2 * MAX_STRING_LENGTH)

int64_t valid_anagram(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t first_length_value = input[0];
    int64_t second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > MAX_STRING_LENGTH ||
        second_length_value < 0 || second_length_value > MAX_STRING_LENGTH) return -1;
    size_t first_length = (size_t)first_length_value;
    size_t second_length = (size_t)second_length_value;
    if (length != 2 + first_length + second_length) return -1;
    size_t first_counts[26] = {0}, second_counts[26] = {0};
    for (size_t index = 0; index < first_length; ++index) {
        int64_t value = input[2 + index];
        if (value < 'a' || value > 'z') return -1;
        ++first_counts[(size_t)(value - 'a')];
    }
    for (size_t index = 0; index < second_length; ++index) {
        int64_t value = input[2 + first_length + index];
        if (value < 'a' || value > 'z') return -1;
        ++second_counts[(size_t)(value - 'a')];
    }
    for (size_t letter = 0; letter < 26; ++letter)
        if (first_counts[letter] != second_counts[letter]) return 0;
    return 1;
}
