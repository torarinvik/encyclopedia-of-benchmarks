/* ASCII alphanumeric palindrome check, ignoring case and punctuation. */
#include <stddef.h>
#include <stdint.h>

static int is_ascii_alphanumeric(int64_t value)
{
    return (value >= '0' && value <= '9') || (value >= 'A' && value <= 'Z') ||
           (value >= 'a' && value <= 'z');
}

static int64_t ascii_lower(int64_t value)
{
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

int64_t valid_palindrome(const int64_t *text, size_t length)
{
    if (length > 4096) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (text[index] < 0 || text[index] > 127) return -1;
    }
    size_t left = 0;
    size_t right = length;
    while (left < right) {
        while (left < right && !is_ascii_alphanumeric(text[left])) ++left;
        while (left < right && !is_ascii_alphanumeric(text[right - 1])) --right;
        if (left < right && ascii_lower(text[left]) != ascii_lower(text[right - 1])) return 0;
        if (left < right) { ++left; --right; }
    }
    return 1;
}
