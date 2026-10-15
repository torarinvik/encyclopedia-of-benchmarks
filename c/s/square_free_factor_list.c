/* Check that an integer factor list has no repeated values. */
#include <stddef.h>
#include <stdint.h>

int64_t square_free_factor_list(const int64_t *values, size_t length)
{
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    for (size_t i = 0; i < length; ++i) {
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;
        for (size_t j = 0; j < i; ++j)
            if (values[i] == values[j]) return 0;
    }
    return 1;
}
