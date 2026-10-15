/* Square a sorted array and emit the results in ascending order. */
#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAY_LENGTH 10000

int64_t squares_of_a_sorted_array(const int64_t *input, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (length > MAX_ARRAY_LENGTH || (length != 0 && input == NULL)) return -1;
    for (size_t index = 0; index < length; ++index) {
        if (input[index] < -10000 || input[index] > 10000) return -1;
        if (index != 0 && input[index - 1] > input[index]) return -1;
    }

    const size_t output_bytes = length * 8;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == NULL)) return -2;

    size_t left = 0, right = length, destination = length;
    while (destination != 0) {
        --destination;
        const int64_t left_value = input[left];
        const int64_t right_value = input[right - 1];
        const int64_t left_magnitude = left_value < 0 ? -left_value : left_value;
        const int64_t right_magnitude = right_value < 0 ? -right_value : right_value;
        int64_t value;
        if (left_magnitude > right_magnitude) {
            value = left_value;
            ++left;
        } else {
            value = right_value;
            --right;
        }
        const uint64_t square = (uint64_t)(value * value);
        for (size_t byte = 0; byte < 8; ++byte)
            output[destination * 8 + byte] = (uint8_t)(square >> (byte * 8));
    }
    return (int64_t)length;
}
