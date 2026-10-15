/* Return the first pattern occurrence using a direct character-by-character scan. */
#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 2050
#define MAX_STRING_LENGTH 1024

int64_t str_str_brute_force(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > MAX_LENGTH) return -1;
    if (packed[0] < 0 || packed[0] > MAX_STRING_LENGTH ||
        packed[1] < 0 || packed[1] > MAX_STRING_LENGTH) return -1;
    const size_t text_length = (size_t)packed[0];
    const size_t pattern_length = (size_t)packed[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (packed[2 + index] < 1 || packed[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;
    if (pattern_length > text_length) return -1;

    const size_t pattern_start = 2 + text_length;
    for (size_t start = 0; start <= text_length - pattern_length; ++start) {
        size_t offset = 0;
        while (offset < pattern_length &&
               packed[2 + start + offset] == packed[pattern_start + offset]) ++offset;
        if (offset == pattern_length) return (int64_t)start;
    }
    return -1;
}
