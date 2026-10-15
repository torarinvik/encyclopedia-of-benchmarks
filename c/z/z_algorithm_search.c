/* Case-insensitive ASCII pattern search using the Z algorithm. */
#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 2047
#define MAX_CONCAT_LENGTH (2 * MAX_SEQUENCE_LENGTH + 1)

static uint32_t fold_ascii(int64_t value)
{
    uint32_t byte = (uint32_t)value;
    return byte >= 'A' && byte <= 'Z' ? byte + ('a' - 'A') : byte;
}

int64_t z_algorithm_search(const int64_t *values, size_t length,
                           uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length < 2) return -1;
    const int64_t text_length_value = values[0];
    const int64_t pattern_length_value = values[1];
    if (text_length_value < 0 || text_length_value > MAX_SEQUENCE_LENGTH ||
        pattern_length_value < 0 || pattern_length_value > MAX_SEQUENCE_LENGTH)
        return -1;
    const size_t text_length = (size_t)text_length_value;
    const size_t pattern_length = (size_t)pattern_length_value;
    if (length != 2 + text_length + pattern_length) return -1;
    for (size_t i = 2; i < length; ++i)
        if (values[i] < 0 || values[i] > 127) return -1;

    if (pattern_length == 0) {
        const size_t count = text_length + 1;
        if (output_capacity < 4 * count || output == NULL) return -2;
        for (size_t i = 0; i < count; ++i) {
            const uint32_t position = (uint32_t)(i + 1);
            for (size_t b = 0; b < 4; ++b) output[4 * i + b] = (uint8_t)(position >> (8 * b));
        }
        return (int64_t)count;
    }

    uint32_t sequence[MAX_CONCAT_LENGTH];
    size_t z[MAX_CONCAT_LENGTH] = {0};
    const size_t total = pattern_length + 1 + text_length;
    for (size_t i = 0; i < pattern_length; ++i) sequence[i] = fold_ascii(values[2 + text_length + i]);
    sequence[pattern_length] = 256; /* Outside the accepted input byte range. */
    for (size_t i = 0; i < text_length; ++i) sequence[pattern_length + 1 + i] = fold_ascii(values[2 + i]);

    size_t left = 0, right = 0;
    for (size_t i = 1; i < total; ++i) {
        if (i < right) {
            const size_t mirror = i - left;
            const size_t remaining = right - i;
            z[i] = z[mirror] < remaining ? z[mirror] : remaining;
        }
        while (i + z[i] < total && sequence[z[i]] == sequence[i + z[i]]) ++z[i];
        if (i + z[i] > right) { left = i; right = i + z[i]; }
    }
    size_t count = 0;
    for (size_t i = pattern_length + 1; i < total; ++i)
        if (z[i] >= pattern_length) ++count;
    if (output_capacity < 4 * count || (count != 0 && output == NULL)) return -2;
    size_t write = 0;
    for (size_t i = pattern_length + 1; i < total; ++i) {
        if (z[i] >= pattern_length) {
            const uint32_t position = (uint32_t)(i - pattern_length);
            for (size_t b = 0; b < 4; ++b) output[4 * write + b] = (uint8_t)(position >> (8 * b));
            ++write;
        }
    }
    return (int64_t)count;
}
