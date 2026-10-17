/* Pointer-relinking selection sort represented by bounded node indices. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_COUNT = 64, MAX_INPUT_LENGTH = 66 };

static void selection_sort_links(const int32_t values[MAX_COUNT], int32_t next[MAX_COUNT],
                                 int32_t *head)
{
    int32_t minimum = *head;
    int32_t current = next[minimum];
    int32_t previous = minimum;
    int32_t sorted_tail = -1;
    while (next[minimum] != -1) {
        while (current != -1) {
            if (values[current] < values[minimum]) {
                if (sorted_tail == -1) {
                    if (previous == minimum) {
                        *head = current;
                        next[minimum] = next[current];
                        next[current] = previous;
                        minimum = current;
                        current = next[previous];
                    } else {
                        *head = current;
                        next[previous] = next[current];
                        next[current] = minimum;
                        minimum = current;
                        current = next[previous];
                    }
                } else {
                    next[sorted_tail] = current;
                    next[previous] = next[current];
                    next[current] = minimum;
                    minimum = current;
                    current = next[previous];
                }
            } else {
                previous = next[previous];
                current = next[current];
            }
        }
        sorted_tail = minimum;
        minimum = next[minimum];
        previous = minimum;
        current = next[minimum];
    }
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t selectionsortlinkedlist(const int64_t *input, size_t length,
                                uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 1 || raw_count > MAX_COUNT || length != 1 + (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;
    int32_t values[MAX_COUNT];
    int32_t next[MAX_COUNT];
    for (size_t index = 0; index < count; ++index) {
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
        values[index] = (int32_t)input[index + 1];
        next[index] = index + 1 < count ? (int32_t)(index + 1) : -1;
    }

    const size_t byte_count = 4 * count;
    if (output == NULL || output_capacity < byte_count) return -2;
    int32_t head = 0;
    selection_sort_links(values, next, &head);
    int32_t node = head;
    for (size_t index = 0; index < count; ++index) {
        write_i32_le(output, 4 * index, values[node]);
        node = next[node];
    }
    return (int64_t)byte_count;
}
