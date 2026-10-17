#include <stddef.h>
#include <stdint.h>

#define MAX_REQUESTS 64
#define MAX_OUTPUT_VALUES 65
#define MAX_INPUT_VALUES 68

static void sort_ascending(int32_t *values, size_t count)
{
    for (size_t i = 1; i < count; ++i) {
        const int32_t value = values[i];
        size_t position = i;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

static void put_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t scan_scheduling(const int32_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 4 || length > MAX_INPUT_VALUES) return -1;
    const int32_t disk_size = input[0];
    const int32_t head = input[1];
    const int32_t direction = input[2];
    const int32_t request_count = input[3];
    if (disk_size < 1 || disk_size > 256 || head < 0 || head >= disk_size ||
        (direction != 0 && direction != 1) || request_count < 0 || request_count > MAX_REQUESTS ||
        length != 4 + (size_t)request_count) return -1;

    int32_t left[MAX_REQUESTS], right[MAX_REQUESTS];
    size_t left_count = 0, right_count = 0;
    for (size_t i = 0; i < (size_t)request_count; ++i) {
        const int32_t request = input[4 + i];
        if (request < 0 || request >= disk_size) return -1;
        if (request < head) left[left_count++] = request;
        else right[right_count++] = request;
    }
    sort_ascending(left, left_count);
    sort_ascending(right, right_count);

    int32_t ordered[MAX_OUTPUT_VALUES];
    size_t count = 0;
    if (request_count > 0) {
        if (direction == 1) {
            for (size_t i = 0; i < right_count; ++i) ordered[count++] = right[i];
            ordered[count++] = disk_size - 1;
            for (size_t i = left_count; i > 0; --i) ordered[count++] = left[i - 1];
        } else {
            for (size_t i = left_count; i > 0; --i) ordered[count++] = left[i - 1];
            ordered[count++] = 0;
            for (size_t i = 0; i < right_count; ++i) ordered[count++] = right[i];
        }
    }
    const size_t bytes = count * 4;
    if (output == NULL || capacity < bytes) return -2;
    for (size_t i = 0; i < count; ++i) put_i32_le(output, i * 4, ordered[i]);
    return (int64_t)bytes;
}
