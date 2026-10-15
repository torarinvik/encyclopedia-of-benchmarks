/* Check for a permutation of one lowercase ASCII string inside another. */
#include <stddef.h>
#include <stdint.h>

#define MAX_STRING_LENGTH 1024
#define MAX_INPUT_LENGTH (2 + 2 * MAX_STRING_LENGTH)

static void adjust_count(int64_t differences[26], int64_t *nonzero, size_t letter, int64_t amount)
{
    if (differences[letter] == 0) ++*nonzero;
    differences[letter] += amount;
    if (differences[letter] == 0) --*nonzero;
}

int64_t permutation_in_string(const int64_t *input, size_t length)
{
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    int64_t first_length_value = input[0], second_length_value = input[1];
    if (first_length_value < 0 || first_length_value > MAX_STRING_LENGTH ||
        second_length_value < 0 || second_length_value > MAX_STRING_LENGTH) return -1;
    size_t first_length = (size_t)first_length_value, second_length = (size_t)second_length_value;
    if (length != 2 + first_length + second_length) return -1;
    for (size_t index = 2; index < length; ++index)
        if (input[index] < 'a' || input[index] > 'z') return -1;
    if (first_length > second_length) return 0;

    int64_t differences[26] = {0}, nonzero = 0;
    for (size_t index = 0; index < first_length; ++index) {
        adjust_count(differences, &nonzero, (size_t)(input[2 + index] - 'a'), 1);
        adjust_count(differences, &nonzero,
                     (size_t)(input[2 + first_length + index] - 'a'), -1);
    }
    if (nonzero == 0) return 1;
    for (size_t start = 0; start < second_length - first_length; ++start) {
        size_t outgoing = 2 + first_length + start;
        size_t incoming = outgoing + first_length;
        adjust_count(differences, &nonzero, (size_t)(input[outgoing] - 'a'), 1);
        adjust_count(differences, &nonzero, (size_t)(input[incoming] - 'a'), -1);
        if (nonzero == 0) return 1;
    }
    return 0;
}
