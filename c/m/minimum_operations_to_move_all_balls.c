#include <stddef.h>
#include <stdint.h>

int64_t minimum_operations_to_move_all_balls(const int64_t *boxes, size_t length,
                                            uint8_t *output, size_t output_capacity) {
    if (length > 256 || (length != 0 && boxes == NULL)) return -1;
    int64_t right_ones = 0;
    int64_t right_distance = 0;
    for (size_t index = 0; index < length; ++index) {
        if (boxes[index] != 0 && boxes[index] != 1) return -1;
        if (boxes[index] == 1) {
            ++right_ones;
            right_distance += (int64_t)index;
        }
    }
    const size_t required_capacity = length * 2;
    if (output_capacity < required_capacity) return -2;
    int64_t left_ones = 0;
    int64_t left_distance = 0;
    for (size_t index = 0; index < length; ++index) {
        if (boxes[index] == 1) {
            --right_ones;
            ++left_ones;
        }
        const int64_t distance = left_distance + right_distance;
        output[2 * index] = (uint8_t)(distance & 0xff);
        output[2 * index + 1] = (uint8_t)((distance >> 8) & 0xff);
        right_distance -= right_ones;
        left_distance += left_ones;
    }
    return (int64_t)length;
}
