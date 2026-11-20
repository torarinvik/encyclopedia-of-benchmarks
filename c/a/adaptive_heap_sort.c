#include <stddef.h>
#include <stdint.h>

#define ADAPTIVE_HEAP_SORT_MAX 1024

static int adaptive_heap_sort_less(const int64_t *values, size_t left, size_t right) {
    return values[left] < values[right]
        || (values[left] == values[right] && left < right);
}

static void adaptive_heap_sort_push(const int64_t *values, size_t *heap,
                                    size_t *heap_length, size_t node) {
    size_t position = (*heap_length)++;
    heap[position] = node;
    while (position > 0) {
        const size_t parent = (position - 1) / 2;
        if (!adaptive_heap_sort_less(values, heap[position], heap[parent])) break;
        const size_t temporary = heap[position];
        heap[position] = heap[parent];
        heap[parent] = temporary;
        position = parent;
    }
}

static size_t adaptive_heap_sort_pop(const int64_t *values, size_t *heap,
                                     size_t *heap_length) {
    const size_t minimum = heap[0];
    --*heap_length;
    if (*heap_length == 0) return minimum;

    heap[0] = heap[*heap_length];
    size_t position = 0;
    while (position < *heap_length / 2) {
        size_t child = position * 2 + 1;
        if (child + 1 < *heap_length
                && adaptive_heap_sort_less(values, heap[child + 1], heap[child])) {
            ++child;
        }
        if (!adaptive_heap_sort_less(values, heap[child], heap[position])) break;
        const size_t temporary = heap[position];
        heap[position] = heap[child];
        heap[child] = temporary;
        position = child;
    }
    return minimum;
}

void adaptive_heap_sort(int64_t *values, size_t length) {
    if (values == NULL || length < 2 || length > ADAPTIVE_HEAP_SORT_MAX) return;

    size_t left[ADAPTIVE_HEAP_SORT_MAX];
    size_t right[ADAPTIVE_HEAP_SORT_MAX];
    size_t construction_stack[ADAPTIVE_HEAP_SORT_MAX];
    size_t candidate_heap[ADAPTIVE_HEAP_SORT_MAX];
    int64_t output[ADAPTIVE_HEAP_SORT_MAX];

    size_t stack_length = 0;
    for (size_t index = 0; index < length; ++index) {
        left[index] = length;
        right[index] = length;
        size_t last = length;
        while (stack_length > 0
                && values[construction_stack[stack_length - 1]] > values[index]) {
            last = construction_stack[--stack_length];
        }
        if (stack_length > 0) right[construction_stack[stack_length - 1]] = index;
        if (last < length) left[index] = last;
        construction_stack[stack_length++] = index;
    }

    size_t heap_length = 0;
    adaptive_heap_sort_push(values, candidate_heap, &heap_length, construction_stack[0]);
    for (size_t output_index = 0; output_index < length; ++output_index) {
        const size_t node = adaptive_heap_sort_pop(values, candidate_heap, &heap_length);
        output[output_index] = values[node];
        if (left[node] < length) {
            adaptive_heap_sort_push(values, candidate_heap, &heap_length, left[node]);
        }
        if (right[node] < length) {
            adaptive_heap_sort_push(values, candidate_heap, &heap_length, right[node]);
        }
    }
    for (size_t index = 0; index < length; ++index) values[index] = output[index];
}
