#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 4096

static int64_t find_next(const int64_t *values, size_t text_length, size_t pattern_length, size_t pattern_start, size_t start)
{
    if (start > text_length || pattern_length > text_length - start) return -1;
    const size_t last = text_length - pattern_length;
    for (size_t position = start; position <= last; ++position) {
        size_t offset = 0;
        while (offset < pattern_length && values[2 + position + offset] == values[pattern_start + offset]) ++offset;
        if (offset == pattern_length) return (int64_t)position;
    }
    return -1;
}

int64_t count_substrings(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || values[0] < 0 || values[0] > MAX_LENGTH || values[1] < 0 || values[1] > MAX_LENGTH) return -1;
    const size_t text_length = (size_t)values[0], pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t i = 2; i < length; ++i) if (values[i] < 0 || values[i] > 127) return -1;
    if (pattern_length == 0) return (int64_t)text_length + 1;
    const size_t pattern_start = 2 + text_length;
    int64_t count = 0;
    int64_t position = find_next(values, text_length, pattern_length, pattern_start, 0);
    while (position >= 0) {
        ++count;
        position = find_next(values, text_length, pattern_length, pattern_start, (size_t)position + 1);
    }
    return count;
}
