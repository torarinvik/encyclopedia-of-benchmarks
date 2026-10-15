/* Sort a copy, then emit each value that appears twice. */
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>

#define MAX_LENGTH 100000

static int compare_i32(const void *left, const void *right)
{
    const int32_t a = *(const int32_t *)left;
    const int32_t b = *(const int32_t *)right;
    return (a > b) - (a < b);
}

int64_t find_all_duplicates_in_array(const int64_t *values, size_t length,
                                     uint8_t *output, size_t output_capacity)
{
    if (length > MAX_LENGTH || (length != 0 && values == NULL)) return -1;
    if (length == 0) return 0;

    int32_t sorted[MAX_LENGTH];
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 1 || values[index] > (int64_t)length) return -1;
        sorted[index] = (int32_t)values[index];
    }
    qsort(sorted, length, sizeof(sorted[0]), compare_i32);

    size_t duplicate_count = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && sorted[end] == sorted[index]) ++end;
        const size_t frequency = end - index;
        if (frequency > 2) return -1;
        if (frequency == 2) ++duplicate_count;
        index = end;
    }

    const size_t output_bytes = duplicate_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;
    size_t destination = 0;
    for (size_t index = 0; index < length;) {
        size_t end = index + 1;
        while (end < length && sorted[end] == sorted[index]) ++end;
        if (end - index == 2) {
            const uint32_t value = (uint32_t)sorted[index];
            for (size_t byte = 0; byte < 4; ++byte)
                output[destination * 4 + byte] = (uint8_t)(value >> (byte * 8));
            ++destination;
        }
        index = end;
    }
    return (int64_t)duplicate_count;
}
