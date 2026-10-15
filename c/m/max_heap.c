#include <stddef.h>
#include <stdint.h>

#define MAX_OPERATIONS 512
#define MAX_INSERTIONS 256

static void store_i64_le(uint8_t *output, size_t offset, int64_t value) {
    uint64_t bits = (uint64_t)value;
    for (size_t i = 0; i < 8; ++i) output[offset + i] = (uint8_t)(bits >> (8 * i));
}

int64_t max_heap(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    size_t operations = (size_t)input[0];
    if (length != 1 + operations * 2) return -1;
    size_t inserts = 0, words = 0;
    for (size_t i = 0; i < operations; ++i) {
        int64_t op = input[1 + 2 * i], value = input[2 + 2 * i];
        if (op < 0 || op > 2) return -1;
        if (op == 0) {
            if (++inserts > MAX_INSERTIONS || value < INT32_MIN || value > INT32_MAX) return -1;
        } else {
            if (value != 0) return -1;
            ++words;
        }
    }
    if (capacity < words * 8 || (words != 0 && output == NULL)) return -2;
    int64_t heap[MAX_INSERTIONS]; size_t size = 0, out = 0;
    for (size_t i = 0; i < operations; ++i) {
        int64_t op = input[1 + 2 * i], value = input[2 + 2 * i], result = INT64_MIN;
        if (op == 0) {
            size_t at = size++; heap[at] = value;
            while (at > 0) { size_t parent = (at - 1) / 2; if (heap[parent] >= heap[at]) break;
                int64_t t = heap[parent]; heap[parent] = heap[at]; heap[at] = t; at = parent; }
            continue;
        }
        if (size != 0) {
            result = heap[0];
            if (op == 2) { heap[0] = heap[--size]; size_t at = 0;
                while (at < size / 2) { size_t child = at * 2 + 1;
                    if (child + 1 < size && heap[child + 1] > heap[child]) ++child;
                    if (heap[at] >= heap[child]) break;
                    int64_t t = heap[at]; heap[at] = heap[child]; heap[child] = t; at = child; }
            }
        }
        store_i64_le(output, out++ * 8, result);
    }
    return (int64_t)words;
}
