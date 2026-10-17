#include <stddef.h>
#include <stdint.h>

#define MAX_LENGTH 256u

static int32_t read_i32_le(const uint8_t *buffer, size_t index)
{
    const size_t offset = index * 4u;
    const uint32_t bits = (uint32_t)buffer[offset]
                        | ((uint32_t)buffer[offset + 1u] << 8u)
                        | ((uint32_t)buffer[offset + 2u] << 16u)
                        | ((uint32_t)buffer[offset + 3u] << 24u);
    return (int32_t)bits;
}

static void write_i32_le(uint8_t *buffer, size_t index, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    const size_t offset = index * 4u;
    buffer[offset] = (uint8_t)bits;
    buffer[offset + 1u] = (uint8_t)(bits >> 8u);
    buffer[offset + 2u] = (uint8_t)(bits >> 16u);
    buffer[offset + 3u] = (uint8_t)(bits >> 24u);
}

static void merge(uint8_t *buffer, size_t start, size_t middle, size_t end,
                  int32_t max_element)
{
    size_t i = start;
    size_t j = middle + 1u;
    size_t k = start;

    while (i <= middle && j <= end) {
        const int32_t left = read_i32_le(buffer, i) % max_element;
        const int32_t right = read_i32_le(buffer, j) % max_element;
        const int32_t current = read_i32_le(buffer, k);
        if (left <= right) {
            write_i32_le(buffer, k++, current + left * max_element);
            ++i;
        } else {
            write_i32_le(buffer, k++, current + right * max_element);
            ++j;
        }
    }
    while (i <= middle) {
        const int32_t current = read_i32_le(buffer, k);
        const int32_t next = read_i32_le(buffer, i) % max_element;
        write_i32_le(buffer, k++, current + next * max_element);
        ++i;
    }
    while (j <= end) {
        const int32_t current = read_i32_le(buffer, k);
        const int32_t next = read_i32_le(buffer, j) % max_element;
        write_i32_le(buffer, k++, current + next * max_element);
        ++j;
    }
    for (size_t index = start; index <= end; ++index)
        write_i32_le(buffer, index, read_i32_le(buffer, index) / max_element);
}

static void merge_sort(uint8_t *buffer, size_t start, size_t end,
                       int32_t max_element)
{
    if (start >= end) return;
    const size_t middle = start + (end - start) / 2u;
    merge_sort(buffer, start, middle, max_element);
    merge_sort(buffer, middle + 1u, end, max_element);
    merge(buffer, start, middle, end, max_element);
}

int64_t merge_sort_no_extra_space(const int32_t *values, size_t length,
                                  uint8_t *output, size_t output_capacity)
{
    if (values == NULL || length > MAX_LENGTH) return -1;
    int32_t max_value = 0;
    for (size_t index = 0; index < length; ++index) {
        if (values[index] < 0 || values[index] > 32767) return -1;
        if (values[index] > max_value) max_value = values[index];
    }
    const size_t output_bytes = length * 4u;
    if (output == NULL || output_capacity < output_bytes) return -2;
    for (size_t index = 0; index < length; ++index)
        write_i32_le(output, index, values[index]);
    if (length > 1u) merge_sort(output, 0u, length - 1u, max_value + 1);
    return (int64_t)output_bytes;
}
