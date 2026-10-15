/* Check whether an ASCII string is a palindrome ignoring ASCII letter case. */
#include <stddef.h>
#include <stdint.h>

static int64_t ascii_lower(int64_t value) {
    return value >= 65 && value <= 90 ? value + 32 : value;
}

int64_t case_insensitive_palindrome(const int64_t *values, size_t length)
{
    if (length > 4096) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 127) return -1;
    }
    for (size_t left = 0; left < length / 2; ++left) {
        if (ascii_lower(values[left]) != ascii_lower(values[length - 1 - left])) return 0;
    }
    return 1;
}
