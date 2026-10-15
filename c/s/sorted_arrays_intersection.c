/* Intersection of three strictly increasing arrays, in ascending order. */
#include <stddef.h>
#include <stdint.h>

#define ARRAY_COUNT 3
#define MAX_ARRAY_LENGTH 64
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t position, int64_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t sorted_arrays_intersection(const int64_t *input, size_t length,
                                   uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < ARRAY_COUNT || length > ARRAY_COUNT * (MAX_ARRAY_LENGTH + 1)) return -1;

    size_t starts[ARRAY_COUNT], sizes[ARRAY_COUNT], position = 0;
    for (size_t array = 0; array < ARRAY_COUNT; ++array) {
        if (position >= length || input[position] < 0 || input[position] > MAX_ARRAY_LENGTH) return -1;
        const size_t size = (size_t)input[position++];
        if (size > length - position) return -1;
        starts[array] = position;
        sizes[array] = size;
        for (size_t index = 0; index < size; ++index) {
            if (input[position + index] < INT32_MIN || input[position + index] > INT32_MAX) return -1;
            if (index > 0 && input[position + index - 1] >= input[position + index]) return -1;
        }
        position += size;
    }
    if (position != length) return -1;

    const size_t maximum_result = sizes[0] < sizes[1]
        ? (sizes[0] < sizes[2] ? sizes[0] : sizes[2])
        : (sizes[1] < sizes[2] ? sizes[1] : sizes[2]);
    if (output_capacity < maximum_result * BYTES_PER_VALUE ||
        (maximum_result != 0 && output == NULL)) return -2;

    size_t cursor[ARRAY_COUNT] = {0, 0, 0};
    size_t result_count = 0;
    while (cursor[0] < sizes[0] && cursor[1] < sizes[1] && cursor[2] < sizes[2]) {
        const int64_t first = input[starts[0] + cursor[0]];
        const int64_t second = input[starts[1] + cursor[1]];
        const int64_t third = input[starts[2] + cursor[2]];
        if (first == second && first == third) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, first);
            ++result_count;
            ++cursor[0]; ++cursor[1]; ++cursor[2];
        } else if (first < second) {
            ++cursor[0];
        } else if (second < third) {
            ++cursor[1];
        } else {
            ++cursor[2];
        }
    }
    return (int64_t)result_count;
}
