/* Check whether an ASCII letter string is case-insensitively sorted. */
#include <stddef.h>
#include <stdint.h>

static int is_ascii_letter(int64_t value)
{
    return (value >= 'A' && value <= 'Z') || (value >= 'a' && value <= 'z');
}

static int64_t lowercase_ascii(int64_t value)
{
    return value >= 'A' && value <= 'Z' ? value + ('a' - 'A') : value;
}

int64_t alphabetical(const int64_t *values, size_t length)
{
    if (length > 256 || (length != 0 && values == NULL)) return -1;
    for (size_t index = 0; index < length; ++index)
        if (values[index] < 0 || values[index] > 127) return -1;

    if (length == 0) return 0;
    int64_t previous = -1;
    for (size_t index = 0; index < length; ++index) {
        if (!is_ascii_letter(values[index])) return 0;
        const int64_t current = lowercase_ascii(values[index]);
        if (current < previous) return 0;
        previous = current;
    }
    return 1;
}
