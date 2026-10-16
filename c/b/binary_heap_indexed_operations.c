/* Bounded operation stream for the source MinHeap API. */
#include <stddef.h>
#include <stdint.h>

static void put_i64(uint8_t *out, size_t slot, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t b = 0; b < 8; ++b) { out[slot * 8 + b] = (uint8_t)bits; bits >>= 8; }
}

static void sift_down(int64_t *heap, size_t size, size_t index) {
    for (;;) {
        size_t left = 2 * index + 1, right = left + 1, smallest = index;
        if (left < size && heap[left] < heap[smallest]) smallest = left;
        if (right < size && heap[right] < heap[smallest]) smallest = right;
        if (smallest == index) return;
        int64_t t = heap[index]; heap[index] = heap[smallest]; heap[smallest] = t;
        index = smallest;
    }
}

static void bubble_up(int64_t *heap, size_t index) {
    while (index > 0) {
        size_t parent = (index - 1) / 2;
        if (heap[parent] <= heap[index]) break;
        int64_t t = heap[index]; heap[index] = heap[parent]; heap[parent] = t;
        index = parent;
    }
}

int64_t binary_heap_indexed_operations(const int64_t *values, size_t length, uint8_t *output, size_t capacity) {
    if (values == NULL || length < 2) return -1;
    int64_t raw_capacity = values[0], raw_count = values[1];
    if (raw_capacity < 1 || raw_capacity > 256 || raw_count < 0 || raw_count > 512 ||
        length != 2 + (size_t)raw_count * 3) return -1;
    int64_t heap[256]; size_t size = 0, outputs = 0;
    for (size_t i = 0; i < (size_t)raw_count; ++i) {
        int64_t op = values[2 + 3 * i], a = values[3 + 3 * i], b = values[4 + 3 * i];
        if (op == 0) {
            if (a < INT32_MIN || a > INT32_MAX || b != 0) return -1;
            if (size < (size_t)raw_capacity) { heap[size] = a; bubble_up(heap, size++); }
        } else if (op == 1 || op == 2) {
            if (a != 0 || b != 0 || (op == 1 && size == 0)) return -1;
            int64_t result = size == 0 ? INT32_MAX : heap[0];
            if (op == 2 && size > 0) { heap[0] = heap[--size]; if (size) sift_down(heap, size, 0); }
            if (output == NULL || (outputs + 1) * 8 > capacity) return -2;
            put_i64(output, outputs++, result);
        } else if (op == 3) {
            if (a < 0 || (uint64_t)a >= size || b < INT32_MIN || b > INT32_MAX || b > heap[a]) return -1;
            heap[a] = b; bubble_up(heap, (size_t)a);
        } else if (op == 4) {
            if (a < 0 || (uint64_t)a >= size || b != 0) return -1;
            heap[a] = INT32_MIN; bubble_up(heap, (size_t)a);
            heap[0] = heap[--size]; if (size) sift_down(heap, size, 0);
        } else return -1;
    }
    size_t bytes = outputs * 8;
    if (bytes > capacity || (bytes > 0 && output == NULL)) return -2;
    return (int64_t)bytes;
}
