/* Count all palindromic substrings by expanding around odd and even centers. */
#include <stddef.h>
#include <stdint.h>

int64_t palindromic_substrings(const int64_t *values, size_t length)
{
    if (length == 0 || length > 1000 || values == NULL) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 'a' || values[index] > 'z') return -1;

    int64_t count = 0;
    for (size_t center = 0; center < length; ++center) {
        ++count;
        size_t left = center, right = center;
        while (left > 0 && right + 1 < length &&
               values[left - 1] == values[right + 1]) {
            ++count;
            --left;
            ++right;
        }

        left = center;
        right = center + 1;
        while (right < length && values[left] == values[right]) {
            ++count;
            if (left == 0 || right + 1 == length) break;
            --left;
            ++right;
        }
    }
    return count;
}
