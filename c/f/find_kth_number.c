#include <stddef.h>
#include <stdint.h>

#define INVALID_RESULT INT64_MIN
#define MAX_VALUES 1024

int64_t find_kth_number(const int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > MAX_VALUES + 1) return INVALID_RESULT;
    const int64_t k = values[0];
    const size_t count = length - 1;
    if (k < 1 || k > (int64_t)count) return INVALID_RESULT;
    int32_t heap[MAX_VALUES];
    for (size_t i = 0; i < count; ++i) {
        const int64_t input = values[i + 1];
        if (input < INT32_MIN || input > INT32_MAX) return INVALID_RESULT;
        size_t index = i;
        heap[index] = (int32_t)input;
        while (index > 0) {
            const size_t parent = (index - 1) / 2;
            if (heap[parent] >= heap[index]) break;
            const int32_t temp = heap[parent]; heap[parent] = heap[index]; heap[index] = temp;
            index = parent;
        }
    }
    size_t heap_size = count;
    for (int64_t removed = 1; removed < k; ++removed) {
        heap_size--;
        heap[0] = heap[heap_size];
        size_t index = 0;
        while (index * 2 + 1 < heap_size) {
            size_t child = index * 2 + 1;
            if (child + 1 < heap_size && heap[child + 1] > heap[child]) child++;
            if (heap[index] >= heap[child]) break;
            const int32_t temp = heap[index]; heap[index] = heap[child]; heap[child] = temp;
            index = child;
        }
    }
    return heap[0];
}
