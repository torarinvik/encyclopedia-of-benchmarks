#include <stddef.h>
#include <stdint.h>

#define MAX_CODE_UNITS 1024

/* mode 0 checks a prefix; mode 1 checks a suffix. Values are UTF-16 code units. */
int64_t string_prefix_suffix(const int64_t *values, size_t length)
{
    if (values == NULL || length < 3 || length > 2052) return -1;
    const int64_t mode = values[0];
    const int64_t text_count_value = values[1];
    const int64_t pattern_count_value = values[2];
    if ((mode != 0 && mode != 1) || text_count_value < 0 || text_count_value > MAX_CODE_UNITS ||
        pattern_count_value < 0 || pattern_count_value > MAX_CODE_UNITS) return -1;
    const size_t text_count = (size_t)text_count_value;
    const size_t pattern_count = (size_t)pattern_count_value;
    if (length != 3 + text_count + pattern_count) return -1;
    for (size_t index = 0; index < text_count + pattern_count; ++index)
        if (values[3 + index] < 0 || values[3 + index] > 65535) return -1;
    if (pattern_count > text_count) return 0;
    const size_t start = mode == 0 ? 0 : text_count - pattern_count;
    for (size_t index = 0; index < pattern_count; ++index)
        if (values[3 + start + index] != values[3 + text_count + index]) return 0;
    return 1;
}
