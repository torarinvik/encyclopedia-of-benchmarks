/* Find the median by binary-searching the partition of the shorter array. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 1000
#define INVALID_RESULT (-2000001)

int64_t median_of_two_sorted_arrays_partition(const int64_t *input, size_t length)
{
    if (input == NULL || length < 3 || length > 2 * MAX_ARRAY_LENGTH + 2) return INVALID_RESULT;
    if (input[0] < 0 || input[0] > MAX_ARRAY_LENGTH ||
        input[1] < 0 || input[1] > MAX_ARRAY_LENGTH) return INVALID_RESULT;

    const size_t first_count = (size_t)input[0];
    const size_t second_count = (size_t)input[1];
    const size_t total_count = first_count + second_count;
    if (total_count == 0 || total_count > 2 * MAX_ARRAY_LENGTH ||
        length != total_count + 2) return INVALID_RESULT;

    const int64_t *first = input + 2;
    const int64_t *second = first + first_count;
    for (size_t index = 0; index < first_count; ++index) {
        if (input[index + 2] < -1000000 || input[index + 2] > 1000000 ||
            (index > 0 && input[index + 1] > input[index + 2])) return INVALID_RESULT;
    }
    for (size_t index = 0; index < second_count; ++index) {
        if (second[index] < -1000000 || second[index] > 1000000 ||
            (index > 0 && second[index - 1] > second[index])) return INVALID_RESULT;
    }

    if (first_count > second_count) {
        const int64_t *temporary_values = first;
        first = second;
        second = temporary_values;
    }
    const size_t short_count = first_count < second_count ? first_count : second_count;
    const size_t long_count = first_count < second_count ? second_count : first_count;
    size_t low = 0, high = short_count;
    const size_t left_count = (total_count + 1) / 2;

    while (low <= high) {
        const size_t first_cut = low + (high - low) / 2;
        const size_t second_cut = left_count - first_cut;
        const int64_t first_left = first_cut == 0 ? INT64_MIN : first[first_cut - 1];
        const int64_t first_right = first_cut == short_count ? INT64_MAX : first[first_cut];
        const int64_t second_left = second_cut == 0 ? INT64_MIN : second[second_cut - 1];
        const int64_t second_right = second_cut == long_count ? INT64_MAX : second[second_cut];

        if (first_left <= second_right && second_left <= first_right) {
            const int64_t left_max = first_left > second_left ? first_left : second_left;
            if (total_count % 2 != 0) return left_max * 2;
            const int64_t right_min = first_right < second_right ? first_right : second_right;
            return left_max + right_min;
        }
        if (first_left > second_right) {
            if (first_cut == 0) return INVALID_RESULT;
            high = first_cut - 1;
        } else {
            low = first_cut + 1;
        }
    }
    return INVALID_RESULT;
}
