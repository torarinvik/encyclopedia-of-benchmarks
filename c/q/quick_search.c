/* Return the first ASCII byte match using a lookahead-byte shift table. */
#include <stddef.h>
#include <stdint.h>

int64_t quick_search(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > 512) return -1;
    if (values[0] < 0 || values[0] > 255 || values[1] < 0 || values[1] > 255) return -1;
    const size_t text_length = (size_t)values[0];
    const size_t pattern_length = (size_t)values[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (values[2 + index] < 0 || values[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    size_t shift[128];
    for (size_t byte = 0; byte < 128; ++byte) shift[byte] = pattern_length;
    const size_t pattern_start = 2 + text_length;
    for (size_t index = 0; index < pattern_length; ++index)
        shift[(size_t)values[pattern_start + index]] = pattern_length - index;

    size_t position = 0;
    while (position <= text_length - pattern_length) {
        size_t index = pattern_length;
        while (index > 0 && values[2 + position + index - 1] == values[pattern_start + index - 1]) --index;
        if (index == 0) return (int64_t)position;
        if (position + pattern_length >= text_length) break;
        position += shift[(size_t)values[2 + position + pattern_length]];
    }
    return -1;
}
