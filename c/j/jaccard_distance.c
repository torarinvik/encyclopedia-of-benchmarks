/* Return one minus character-set Jaccard similarity for two ASCII strings. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_STRING_LENGTH 64

double jaccard_distance(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t left_value = values[0];
    const int64_t right_value = values[1];
    if (left_value < 0 || left_value > MAX_STRING_LENGTH ||
        right_value < 0 || right_value > MAX_STRING_LENGTH) return INVALID_RESULT;
    const size_t left_length = (size_t)left_value;
    const size_t right_length = (size_t)right_value;
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    for (size_t i = 0; i < left_length; ++i)
        if (values[2 + i] < 32 || values[2 + i] > 126) return INVALID_RESULT;
    for (size_t i = 0; i < right_length; ++i)
        if (values[2 + left_length + i] < 32 || values[2 + left_length + i] > 126) return INVALID_RESULT;

    size_t intersection = 0;
    size_t union_length = 0;
    for (size_t i = 0; i < left_length; ++i) {
        int seen_before = 0;
        for (size_t k = 0; k < i; ++k)
            if (values[2 + k] == values[2 + i]) { seen_before = 1; break; }
        if (seen_before) continue;
        ++union_length;
        for (size_t j = 0; j < right_length; ++j)
            if (values[2 + i] == values[2 + left_length + j]) { ++intersection; break; }
    }
    for (size_t j = 0; j < right_length; ++j) {
        int seen_before = 0;
        for (size_t k = 0; k < j; ++k)
            if (values[2 + left_length + k] == values[2 + left_length + j]) { seen_before = 1; break; }
        if (seen_before) continue;
        int in_left = 0;
        for (size_t i = 0; i < left_length; ++i)
            if (values[2 + i] == values[2 + left_length + j]) { in_left = 1; break; }
        if (!in_left) ++union_length;
    }
    if (union_length == 0) return 0.0;
    return 1.0 - (double)intersection / (double)union_length;
}
