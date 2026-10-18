#include <stddef.h>
#include <stdint.h>

#define MAX_OPS 64u
#define MAX_INPUT 130u
#define MAX_OUTPUT (4u * MAX_OPS)

int64_t priority_queue(const int64_t *input, size_t input_length,
                       uint8_t *output, size_t capacity) {
    if (input == NULL || input_length == 0 || input_length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (int64_t)MAX_OPS) return -1;
    const size_t op_count = (size_t)input[0];
    int32_t heap[MAX_OPS], seen[MAX_OPS];
    uint8_t staged[MAX_OUTPUT];
    size_t heap_size = 0, seen_count = 0, offset = 1, output_size = 0;

    for (size_t op_index = 0; op_index < op_count; ++op_index) {
        if (offset >= input_length) return -1;
        const int64_t op = input[offset++];
        if (op == 0) {
            if (offset >= input_length) return -1;
            const int64_t raw = input[offset++];
            if (raw < INT32_MIN || raw > INT32_MAX) return -1;
            const int32_t value = (int32_t)raw;
            for (size_t i = 0; i < seen_count; ++i) if (seen[i] == value) return -1;
            seen[seen_count++] = value;
            size_t i = heap_size++;
            heap[i] = value;
            while (i != 0) {
                size_t parent = (i - 1u) / 2u;
                if (heap[parent] <= heap[i]) break;
                int32_t tmp = heap[parent]; heap[parent] = heap[i]; heap[i] = tmp;
                i = parent;
            }
        } else if (op == 1 || op == 2) {
            if (heap_size == 0) return -1;
            const int32_t result = heap[0];
            if (output_size + 4u > MAX_OUTPUT) return -1;
            const uint32_t bits = (uint32_t)result;
            staged[output_size++] = (uint8_t)bits;
            staged[output_size++] = (uint8_t)(bits >> 8);
            staged[output_size++] = (uint8_t)(bits >> 16);
            staged[output_size++] = (uint8_t)(bits >> 24);
            if (op == 2) {
                heap[0] = heap[--heap_size];
                size_t i = 0;
                while (i < heap_size) {
                    size_t child = 2u * i + 1u;
                    if (child >= heap_size) break;
                    if (child + 1u < heap_size && heap[child + 1u] < heap[child]) ++child;
                    if (heap[i] <= heap[child]) break;
                    int32_t tmp = heap[i]; heap[i] = heap[child]; heap[child] = tmp;
                    i = child;
                }
            }
        } else return -1;
    }
    if (offset != input_length) return -1;
    if (output == NULL || capacity < output_size) return -2;
    for (size_t i = 0; i < output_size; ++i) output[i] = staged[i];
    return (int64_t)output_size;
}
