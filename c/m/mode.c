/* Find the unique mode of a bounded array of small nonnegative integers. */
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>

int64_t mode(const int64_t *values, size_t length)
{
    if (values == NULL || length == 0 || length > 4096) return -1;
    size_t counts[256] = {0};
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < 0 || values[i] > 255) return -1;
        ++counts[(size_t)values[i]];
    }
    size_t maximum = 0;
    int64_t result = -1;
    bool unique = true;
    for (size_t i = 0; i < 256; ++i) {
        if (counts[i] > maximum) {
            maximum = counts[i];
            result = (int64_t)i;
            unique = true;
        } else if (counts[i] != 0 && counts[i] == maximum) {
            unique = false;
        }
    }
    return unique ? result : -1;
}
