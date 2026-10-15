/* Merge two ascending i32 arrays and return twice their exact median. */
#include <stddef.h>
#include <stdint.h>

#define MAX_TOTAL_LENGTH 1024

int64_t median_of_two_sorted_arrays(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > MAX_TOTAL_LENGTH + 2) return -1;
    if (input[0] < 0 || input[0] > MAX_TOTAL_LENGTH ||
        input[1] < 0 || input[1] > MAX_TOTAL_LENGTH) return -1;
    const size_t first_count = (size_t)input[0], second_count = (size_t)input[1];
    const size_t total_count = first_count + second_count;
    if (total_count == 0 || total_count > MAX_TOTAL_LENGTH || length != total_count + 2)
        return -1;
    const size_t second_start = first_count + 2;
    for (size_t index = 0; index < first_count; ++index) {
        const int64_t value = input[index + 2];
        if (value < INT32_MIN || value > INT32_MAX ||
            (index != 0 && input[index + 1] > value)) return -1;
    }
    for (size_t index = 0; index < second_count; ++index) {
        const int64_t value = input[second_start + index];
        if (value < INT32_MIN || value > INT32_MAX ||
            (index != 0 && input[second_start + index - 1] > value)) return -1;
    }

    int32_t merged[MAX_TOTAL_LENGTH];
    size_t first_index = 0, second_index = 0, written = 0;
    while (first_index < first_count && second_index < second_count) {
        if (input[first_index + 2] <= input[second_start + second_index])
            merged[written++] = (int32_t)input[first_index++ + 2];
        else
            merged[written++] = (int32_t)input[second_start + second_index++];
    }
    while (first_index < first_count)
        merged[written++] = (int32_t)input[first_index++ + 2];
    while (second_index < second_count)
        merged[written++] = (int32_t)input[second_start + second_index++];

    if (total_count % 2 != 0) return (int64_t)merged[total_count / 2] * 2;
    return (int64_t)merged[total_count / 2 - 1] + merged[total_count / 2];
}
