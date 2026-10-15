/* Return twice the statistical median using a local insertion-sorted copy. */
#include <stddef.h>
#include <stdint.h>

int64_t median(const int64_t *values, size_t length)
{
    if (length == 0 || length > 1024) return 0;
    int64_t ordered[1024];
    for (size_t index = 0; index < length; ++index) ordered[index] = values[index];
    for (size_t index = 1; index < length; ++index) {
        const int64_t value = ordered[index];
        size_t cursor = index;
        while (cursor > 0 && ordered[cursor - 1] > value) {
            ordered[cursor] = ordered[cursor - 1];
            --cursor;
        }
        ordered[cursor] = value;
    }
    if (length % 2 != 0) return ordered[length / 2] * 2;
    return ordered[length / 2 - 1] + ordered[length / 2];
}
