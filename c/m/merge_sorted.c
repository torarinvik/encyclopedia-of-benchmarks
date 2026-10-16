#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 64
#define MAX_INPUT_LENGTH (2 + 2 * MAX_ARRAY_LENGTH)
#define MAX_PARSEABLE_INPUT_LENGTH (MAX_INPUT_LENGTH + 1)
#define MIN_VALUE INT64_C(-1000000)
#define MAX_VALUE INT64_C(1000000)
#define CHECKSUM_OFFSET INT64_C(1000001)

int64_t merge_sorted(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (values[0] < 0 || values[0] > MAX_ARRAY_LENGTH ||
        values[1] < 0 || values[1] > MAX_ARRAY_LENGTH) return -1;

    const size_t left_count = (size_t)values[0];
    const size_t right_count = (size_t)values[1];
    if (length != 2 + left_count + right_count) return -1;
    const size_t right_start = 2 + left_count;
    for (size_t index = 0; index < left_count; ++index) {
        const int64_t value = values[2 + index];
        if (value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[2 + index - 1] > value)) return -1;
    }
    for (size_t index = 0; index < right_count; ++index) {
        const int64_t value = values[right_start + index];
        if (value < MIN_VALUE || value > MAX_VALUE ||
            (index > 0 && values[right_start + index - 1] > value)) return -1;
    }

    size_t left_index = 0, right_index = 0, output_index = 0;
    int64_t checksum = 0;
    while (left_index < left_count && right_index < right_count) {
        int64_t value;
        if (values[2 + left_index] <= values[right_start + right_index])
            value = values[2 + left_index++];
        else
            value = values[right_start + right_index++];
        checksum += (int64_t)(output_index + 1) * (value + CHECKSUM_OFFSET);
        ++output_index;
    }
    while (left_index < left_count) {
        const int64_t value = values[2 + left_index++];
        checksum += (int64_t)(output_index + 1) * (value + CHECKSUM_OFFSET);
        ++output_index;
    }
    while (right_index < right_count) {
        const int64_t value = values[right_start + right_index++];
        checksum += (int64_t)(output_index + 1) * (value + CHECKSUM_OFFSET);
        ++output_index;
    }
    return checksum;
}
