#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 100000

static int is_palindrome_range(const int64_t *text, size_t left, size_t right)
{
    while (left < right) {
        if (text[left] != text[right - 1]) return 0;
        ++left;
        --right;
    }
    return 1;
}

int64_t almost_palindrome_checker(const int64_t *text, size_t length)
{
    if (length > MAX_LENGTH) return -1;
    for (size_t index = 0; index < length; ++index)
        if (text[index] < 'a' || text[index] > 'z') return -1;
    size_t left = 0;
    size_t right = length;
    while (left < right) {
        if (text[left] != text[right - 1])
            return is_palindrome_range(text, left + 1, right) ||
                   is_palindrome_range(text, left, right - 1);
        ++left;
        --right;
    }
    return 1;
}
