#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 1024

static int64_t lower_ascii(int64_t value)
{
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

int64_t check_palindrome2(const int64_t *values, size_t length,
                          uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i)
        if (values[i] < 32 || values[i] > 126) return -1;

    size_t start = 0;
    size_t end = length;
    while (start < end && values[start] == 32) ++start;
    while (end > start && values[end - 1] == 32) --end;
    const size_t normalized_length = end - start;
    if (normalized_length == 0 || (normalized_length == 1 && values[start] == '0')) return -1;

    int palindrome = 1;
    for (size_t left = 0; left < normalized_length / 2; ++left) {
        const size_t right = normalized_length - left - 1;
        if (lower_ascii(values[start + left]) != lower_ascii(values[start + right])) palindrome = 0;
    }

    const char *suffix = palindrome ? " - a palindrome string.\n" : " - not a palindrome string.\n";
    const size_t suffix_length = palindrome ? 24 : 28;
    if (output == NULL || output_capacity < normalized_length + suffix_length) return -2;
    for (size_t i = 0; i < normalized_length; ++i)
        output[i] = (uint8_t)lower_ascii(values[start + i]);
    for (size_t i = 0; i < suffix_length; ++i)
        output[normalized_length + i] = (uint8_t)suffix[i];
    return (int64_t)(normalized_length + suffix_length);
}
