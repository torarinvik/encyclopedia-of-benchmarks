#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 64
#define BYTES_PER_VALUE 4

static void store_i32_le(uint8_t *output, size_t position, int64_t value) {
    const uint32_t bits = (uint32_t)(int32_t)value;
    for (size_t byte = 0; byte < BYTES_PER_VALUE; ++byte)
        output[position + byte] = (uint8_t)(bits >> (byte * 8));
}

int64_t compress(const int64_t *input, size_t length,
                 uint8_t *output, size_t output_capacity) {
    if (input == NULL || length < 1 || length > MAX_LENGTH + 1) return -1;
    const int64_t count_value = input[0];
    if (count_value < 0 || count_value > MAX_LENGTH || length != 1 + (size_t)count_value) return -1;
    const size_t count = (size_t)count_value;
    for (size_t index = 0; index < count; ++index)
        if (input[1 + index] < INT32_MIN || input[1 + index] > INT32_MAX) return -1;

    const size_t maximum_bytes = count * BYTES_PER_VALUE;
    if (output_capacity < maximum_bytes || (maximum_bytes > 0 && output == NULL)) return -2;
    size_t result_count = 0;
    int64_t previous = 0;
    for (size_t index = 0; index < count; ++index) {
        const int64_t value = input[1 + index];
        if (index == 0 || value != previous) {
            store_i32_le(output, result_count * BYTES_PER_VALUE, value);
            ++result_count;
        }
        previous = value;
    }
    return (int64_t)result_count;
}
