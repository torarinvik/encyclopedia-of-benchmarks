/* Priority-queue sort using a bounded binary min-heap. */
#include <stddef.h>
#include <stdint.h>

enum { MAX_COUNT = 128, MAX_INPUT_LENGTH = 130, MAX_OUTPUT_BYTES = 512 };

static void heap_push(int32_t heap[MAX_COUNT], size_t *size, int32_t value)
{
    size_t child = (*size)++;
    heap[child] = value;
    while (child > 0) {
        const size_t parent = (child - 1) / 2;
        if (heap[parent] <= heap[child]) break;
        const int32_t temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        child = parent;
    }
}

static int32_t heap_pop(int32_t heap[MAX_COUNT], size_t *size)
{
    const int32_t minimum = heap[0];
    --*size;
    if (*size == 0) return minimum;
    heap[0] = heap[*size];
    size_t parent = 0;
    for (;;) {
        const size_t left = 2 * parent + 1;
        if (left >= *size) break;
        const size_t right = left + 1;
        size_t smaller = left;
        if (right < *size && heap[right] < heap[left]) smaller = right;
        if (heap[parent] <= heap[smaller]) break;
        const int32_t temporary = heap[parent];
        heap[parent] = heap[smaller];
        heap[smaller] = temporary;
        parent = smaller;
    }
    return minimum;
}

static void write_i32_le(uint8_t *output, size_t offset, int32_t value)
{
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t priority_queue_sort(const int64_t *input, size_t length,
                            uint8_t *output, size_t output_capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    const int64_t raw_count = input[0];
    if (raw_count < 0 || raw_count > MAX_COUNT || length != 1 + (size_t)raw_count) return -1;
    const size_t count = (size_t)raw_count;
    for (size_t index = 0; index < count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;

    const size_t byte_count = 4 * count;
    if (output == NULL || output_capacity < byte_count) return -2;

    int32_t heap[MAX_COUNT];
    size_t heap_size = 0;
    for (size_t index = 0; index < count; ++index)
        heap_push(heap, &heap_size, (int32_t)input[index + 1]);
    for (size_t index = 0; index < count; ++index)
        write_i32_le(output, 4 * index, heap_pop(heap, &heap_size));
    return (int64_t)byte_count;
}
