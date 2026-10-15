#include <stddef.h>
#include <stdint.h>

static void sift_down(int64_t *heap, size_t count, size_t index) {
    for (;;) {
        size_t largest = index;
        size_t left = index * 2 + 1;
        size_t right = left + 1;
        if (left < count && heap[left] > heap[largest]) largest = left;
        if (right < count && heap[right] > heap[largest]) largest = right;
        if (largest == index) return;
        int64_t temporary = heap[index]; heap[index] = heap[largest]; heap[largest] = temporary;
        index = largest;
    }
}

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(255));
        bits >>= 8;
    }
}

int64_t heap_max_push_peek_pop(const int64_t *values, size_t length,
                               uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2 || length > 257) return -1;
    int64_t raw_count = values[0];
    if (raw_count < 1 || raw_count > 256 || length != (size_t)raw_count + 1) return -1;
    size_t count = (size_t)raw_count;
    int64_t heap[256];
    for (size_t index = 0; index < count; ++index) {
        int64_t value = values[index + 1];
        if (value < 1 || value > INT64_C(1000000000)) return -1;
        size_t position = index;
        heap[position] = value;
        while (position > 0) {
            size_t parent = (position - 1) / 2;
            if (heap[parent] >= heap[position]) break;
            int64_t temporary = heap[parent]; heap[parent] = heap[position]; heap[position] = temporary;
            position = parent;
        }
    }
    size_t output_bytes = 8 * count;
    if (output == NULL || capacity < output_bytes) return -2;
    size_t remaining = count;
    for (size_t index = 0; index < count; ++index) {
        int64_t maximum = heap[0];
        store_i64_le(output, 8 * index, maximum);
        --remaining;
        if (remaining > 0) { heap[0] = heap[remaining]; sift_down(heap, remaining, 0); }
    }
    return (int64_t)output_bytes;
}
