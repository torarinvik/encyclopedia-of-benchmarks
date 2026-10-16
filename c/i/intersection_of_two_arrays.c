#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 64
#define MAX_INPUT_LENGTH (2 * (MAX_ARRAY_LENGTH + 1))
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t position, int64_t value) {
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t intersection_of_two_arrays(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 2 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t first_length_value = input[0];
    if (first_length_value < 0 || first_length_value > MAX_ARRAY_LENGTH) return -1;
    const size_t first_length = (size_t)first_length_value;
    const size_t second_length_position = 1 + first_length;
    if (second_length_position >= length) return -1;
    const int64_t second_length_value = input[second_length_position];
    if (second_length_value < 0 || second_length_value > MAX_ARRAY_LENGTH) return -1;
    const size_t second_length = (size_t)second_length_value;
    const size_t second_start = second_length_position + 1;
    if (second_length != length - second_start) return -1;

    for (size_t index = 0; index < first_length; ++index) {
        const int64_t value = input[1 + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 0 && input[index] > value) return -1;
    }
    for (size_t index = 0; index < second_length; ++index) {
        const int64_t value = input[second_start + index];
        if (value < INT32_MIN || value > INT32_MAX) return -1;
        if (index > 0 && input[second_start + index - 1] > value) return -1;
    }

    const size_t maximum_result = first_length < second_length ? first_length : second_length;
    if (output_capacity < maximum_result * BYTES_PER_VALUE || (maximum_result > 0 && output == NULL)) return -2;
    size_t first_index = 0, second_index = 0, result_count = 0;
    int64_t previous_value = 0;
    while (first_index < first_length && second_index < second_length) {
        const int64_t first = input[1 + first_index];
        const int64_t second = input[second_start + second_index];
        if (first < second) {
            ++first_index;
        } else if (first > second) {
            ++second_index;
        } else {
            if (result_count == 0 || first != previous_value) {
                store_i32_le(output, result_count * BYTES_PER_VALUE, first);
                previous_value = first;
                ++result_count;
            }
            ++first_index;
            ++second_index;
        }
    }
    return (int64_t)result_count;
}
