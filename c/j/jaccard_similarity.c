/* Return intersection-over-union similarity for two unique ASCII sets. */
#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT (-1.0e300)
#define MAX_SET_LENGTH 64

double jaccard_similarity(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2) return INVALID_RESULT;
    const int64_t left_length_value = values[0];
    const int64_t right_length_value = values[1];
    if (left_length_value < 0 || left_length_value > MAX_SET_LENGTH ||
        right_length_value < 0 || right_length_value > MAX_SET_LENGTH ||
        (left_length_value == 0 && right_length_value == 0)) return INVALID_RESULT;
    const size_t left_length = (size_t)left_length_value;
    const size_t right_length = (size_t)right_length_value;
    if (length != 2 + left_length + right_length) return INVALID_RESULT;

    for (size_t i = 0; i < left_length; ++i) {
        const int64_t value = values[2 + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (size_t before = 0; before < i; ++before)
            if (values[2 + before] == value) return INVALID_RESULT;
    }
    for (size_t i = 0; i < right_length; ++i) {
        const int64_t value = values[2 + left_length + i];
        if (value < 32 || value > 126) return INVALID_RESULT;
        for (size_t before = 0; before < i; ++before)
            if (values[2 + left_length + before] == value) return INVALID_RESULT;
    }

    size_t intersection = 0;
    for (size_t i = 0; i < left_length; ++i)
        for (size_t j = 0; j < right_length; ++j)
            if (values[2 + i] == values[2 + left_length + j]) { ++intersection; break; }
    const size_t union_length = left_length + right_length - intersection;
    return (double)intersection / (double)union_length;
}
