/* Compare the linked-list value sequence from both ends without mutation. */
#include <stddef.h>
#include <stdint.h>

int64_t palindrome_linked_list(const int64_t *values, size_t length)
{
    if (length > 100000) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 9) return -1;
    }

    size_t left = 0;
    size_t right = length;
    while (left < right) {
        --right;
        if (values[left] != values[right]) return 0;
        ++left;
    }
    return 1;
}
