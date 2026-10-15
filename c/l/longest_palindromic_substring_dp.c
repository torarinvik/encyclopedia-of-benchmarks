/* Find the rightmost longest ASCII alphanumeric palindrome with gap-based DP. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

static int is_ascii_alphanumeric(int64_t value)
{
    return (value >= '0' && value <= '9') ||
           (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

int64_t longest_palindromic_substring_dp(const int64_t *values, size_t length,
                                         uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length == 0 || length > 1000) return -1;
    for (size_t index = 0; index < length; ++index)
        if (!is_ascii_alphanumeric(values[index])) return -1;

    bool *palindrome = calloc(length * length, sizeof(*palindrome));
    if (palindrome == NULL) return -1;

    size_t best_start = 0;
    size_t best_end = 0;
    for (size_t gap = 0; gap < length; ++gap) {
        for (size_t start = 0, end = gap; end < length; ++start, ++end) {
            bool is_palindrome;
            if (gap == 0) {
                is_palindrome = true;
            } else if (gap == 1) {
                is_palindrome = values[start] == values[end];
            } else {
                is_palindrome = values[start] == values[end] &&
                    palindrome[(start + 1) * length + end - 1];
            }
            palindrome[start * length + end] = is_palindrome;
            if (is_palindrome) {
                best_start = start;
                best_end = end;
            }
        }
    }

    const size_t best_length = best_end - best_start + 1;
    if (output == NULL || output_capacity < best_length) {
        free(palindrome);
        return -2;
    }
    for (size_t index = 0; index < best_length; ++index)
        output[index] = (uint8_t)values[best_start + index];
    free(palindrome);
    return (int64_t)best_length;
}
