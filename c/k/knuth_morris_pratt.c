/* Find the first byte occurrence of a pattern using the Knuth-Morris-Pratt algorithm. */
#include <stddef.h>
#include <stdint.h>

int64_t knuth_morris_pratt(const int64_t *packed, size_t length)
{
    if (packed == NULL || length < 2 || length > 8194) return -1;
    if (packed[0] < 0 || packed[0] > 4096 || packed[1] < 0 || packed[1] > 4096) return -1;
    const size_t text_length = (size_t)packed[0];
    const size_t pattern_length = (size_t)packed[1];
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t index = 0; index < text_length + pattern_length; ++index)
        if (packed[2 + index] < 0 || packed[2 + index] > 127) return -1;
    if (pattern_length == 0) return 0;

    const size_t pattern_start = 2 + text_length;
    size_t prefix[4096];
    prefix[0] = 0;
    for (size_t index = 1, matched = 0; index < pattern_length; ++index) {
        while (matched > 0 && packed[pattern_start + index] != packed[pattern_start + matched])
            matched = prefix[matched - 1];
        if (packed[pattern_start + index] == packed[pattern_start + matched]) ++matched;
        prefix[index] = matched;
    }

    for (size_t index = 0, matched = 0; index < text_length; ++index) {
        while (matched > 0 && packed[2 + index] != packed[pattern_start + matched])
            matched = prefix[matched - 1];
        if (packed[2 + index] == packed[pattern_start + matched]) ++matched;
        if (matched == pattern_length) return (int64_t)(index + 1 - pattern_length);
    }
    return -1;
}
