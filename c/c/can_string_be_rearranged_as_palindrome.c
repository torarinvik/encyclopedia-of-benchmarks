/* Can lowercase ASCII letters be rearranged into a palindrome? */
#include <stddef.h>
#include <stdint.h>

int64_t can_string_be_rearranged_as_palindrome(const int64_t *text, size_t length)
{
    if (length == 0 || length > 4096) return -1;
    size_t counts[26] = {0};
    size_t odd_count = 0;
    for (size_t index = 0; index < length; ++index) {
        if (text[index] < 'a' || text[index] > 'z') return -1;
        const size_t letter = (size_t)(text[index] - 'a');
        if ((counts[letter] & 1U) == 0) ++odd_count;
        else --odd_count;
        ++counts[letter];
    }
    return odd_count <= 1 ? 1 : 0;
}
