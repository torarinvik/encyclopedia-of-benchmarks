#include <stddef.h>
#include <stdint.h>

#define MAX_SEQUENCE_LENGTH 4096
#define MAX_PACKED_LENGTH 8194

int64_t validate_subsequence(const int64_t *values, size_t length)
{
    if (values == NULL || length < 2 || length > MAX_PACKED_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_SEQUENCE_LENGTH ||
        values[1] < 0 || values[1] > MAX_SEQUENCE_LENGTH) return -1;
    const size_t array_length = (size_t)values[0];
    const size_t sequence_length = (size_t)values[1];
    if (length != 2 + array_length + sequence_length) return -1;
    for (size_t i = 2; i < length; ++i)
        if (values[i] < INT32_MIN || values[i] > INT32_MAX) return -1;

    if (array_length == 0) return 0;
    if (sequence_length == 0) return 1;
    const size_t sequence_start = 2 + array_length;
    size_t array_index = 0, sequence_index = 0;
    while (sequence_index < sequence_length && array_index < array_length) {
        if (values[sequence_start + sequence_index] == values[2 + array_index]) ++sequence_index;
        ++array_index;
    }
    return sequence_index == sequence_length ? 1 : 0;
}
