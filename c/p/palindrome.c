/* Check whether an exact ASCII string is a palindrome. */
#include <stddef.h>
#include <stdint.h>

int64_t palindrome(const int64_t *values, size_t length)
{
    if (length > 4096) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (size_t left = 0; left < length / 2; ++left) {
        if (values[left] != values[length - 1 - left]) return 0;
    }
    return 1;
}
