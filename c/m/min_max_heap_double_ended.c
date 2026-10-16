#include <stddef.h>
#include <stdint.h>

#define MAX_INITIAL 64
#define MAX_OPERATIONS 128
#define MAX_HEAP_SIZE (MAX_INITIAL + MAX_OPERATIONS)
#define INVALID_RESULT INT64_C(-1)
#define CAPACITY_RESULT INT64_C(-2)

typedef struct {
    int32_t values[MAX_HEAP_SIZE];
    size_t count;
} MinMaxHeap;

static int is_min_level(size_t index) {
    size_t value = index + 1;
    unsigned depth = 0;
    while (value > 1) { value >>= 1; ++depth; }
    return (depth & 1u) == 0;
}

static void swap_values(MinMaxHeap *heap, size_t left, size_t right) {
    int32_t temp = heap->values[left];
    heap->values[left] = heap->values[right];
    heap->values[right] = temp;
}

static size_t best_descendant(const MinMaxHeap *heap, size_t index, int find_min) {
    size_t best = SIZE_MAX;
    for (size_t offset = 0; offset < 6; ++offset) {
        const size_t candidate = offset < 2 ? 2 * index + 1 + offset : 4 * index + 1 + offset;
        if (candidate >= heap->count) break;
        if (best == SIZE_MAX || (find_min ? heap->values[candidate] < heap->values[best]
                                          : heap->values[candidate] > heap->values[best])) best = candidate;
    }
    return best;
}

static void push_down(MinMaxHeap *heap, size_t index, int find_min) {
    while (index < heap->count) {
        const size_t best = best_descendant(heap, index, find_min);
        if (best == SIZE_MAX) return;
        const int grandchild = best > 2 && (best - 3) / 4 == index;
        const int improves = find_min ? heap->values[best] < heap->values[index]
                                      : heap->values[best] > heap->values[index];
        if (grandchild) {
            if (!improves) return;
            swap_values(heap, best, index);
            const size_t parent = (best - 1) / 2;
            const int parent_violation = find_min ? heap->values[best] > heap->values[parent]
                                                   : heap->values[best] < heap->values[parent];
            if (parent_violation) swap_values(heap, best, parent);
            index = best;
        } else {
            if (improves) swap_values(heap, best, index);
            return;
        }
    }
}

static void push_up_min(MinMaxHeap *heap, size_t index) {
    while (index > 2) {
        const size_t grandparent = (index - 3) / 4;
        if (heap->values[index] >= heap->values[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

static void push_up_max(MinMaxHeap *heap, size_t index) {
    while (index > 2) {
        const size_t grandparent = (index - 3) / 4;
        if (heap->values[index] <= heap->values[grandparent]) return;
        swap_values(heap, index, grandparent);
        index = grandparent;
    }
}

static void push_up(MinMaxHeap *heap, size_t index) {
    if (index == 0) return;
    const size_t parent = (index - 1) / 2;
    if (is_min_level(index)) {
        if (heap->values[index] > heap->values[parent]) {
            swap_values(heap, index, parent);
            push_up_max(heap, parent);
        } else {
            push_up_min(heap, index);
        }
    } else if (heap->values[index] < heap->values[parent]) {
        swap_values(heap, index, parent);
        push_up_min(heap, parent);
    } else {
        push_up_max(heap, index);
    }
}

static void add_value(MinMaxHeap *heap, int32_t value) {
    const size_t index = heap->count++;
    heap->values[index] = value;
    push_up(heap, index);
}

static size_t max_index(const MinMaxHeap *heap) {
    if (heap->count < 2) return 0;
    if (heap->count == 2) return 1;
    return heap->values[1] > heap->values[2] ? 1 : 2;
}

static int32_t extract_at(MinMaxHeap *heap, size_t index) {
    const int32_t result = heap->values[index];
    --heap->count;
    if (index != heap->count) heap->values[index] = heap->values[heap->count];
    if (heap->count != 0 && index < heap->count) push_down(heap, index, is_min_level(index));
    return result;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void insertion_sort(int32_t *values, size_t count) {
    for (size_t index = 1; index < count; ++index) {
        const int32_t value = values[index];
        size_t position = index;
        while (position > 0 && values[position - 1] > value) {
            values[position] = values[position - 1];
            --position;
        }
        values[position] = value;
    }
}

int64_t min_max_heap_double_ended(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2) return INVALID_RESULT;
    const int64_t initial_value = input[0];
    if (initial_value < 0 || initial_value > MAX_INITIAL) return INVALID_RESULT;
    const size_t initial_count = (size_t)initial_value;
    if (length < initial_count + 2) return INVALID_RESULT;
    const int64_t operations_value = input[initial_count + 1];
    if (operations_value < 0 || operations_value > MAX_OPERATIONS) return INVALID_RESULT;
    const size_t operation_count = (size_t)operations_value;
    if (length != initial_count + 2 + 2 * operation_count) return INVALID_RESULT;
    for (size_t index = 0; index < initial_count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return INVALID_RESULT;
    for (size_t op_index = 0; op_index < operation_count; ++op_index) {
        const int64_t opcode = input[initial_count + 2 + 2 * op_index];
        const int64_t argument = input[initial_count + 3 + 2 * op_index];
        if (opcode < 0 || opcode > 5) return INVALID_RESULT;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX) return INVALID_RESULT;
        } else if (argument != 0) return INVALID_RESULT;
    }

    MinMaxHeap heap = { .count = initial_count };
    for (size_t index = 0; index < initial_count; ++index) heap.values[index] = (int32_t)input[index + 1];
    for (size_t index = initial_count / 2; index > 0; --index) push_down(&heap, index - 1, is_min_level(index - 1));
    int64_t event_results[MAX_OPERATIONS];
    size_t event_count = 0;
    for (size_t op_index = 0; op_index < operation_count; ++op_index) {
        const int64_t opcode = input[initial_count + 2 + 2 * op_index];
        const int32_t argument = (int32_t)input[initial_count + 3 + 2 * op_index];
        if (opcode == 0) add_value(&heap, argument);
        else if (opcode == 1 || opcode == 3) {
            if (heap.count == 0) return INVALID_RESULT;
            event_results[event_count++] = opcode == 1 ? heap.values[0] : extract_at(&heap, 0);
        } else if (opcode == 2 || opcode == 4) {
            if (heap.count == 0) return INVALID_RESULT;
            const size_t index = max_index(&heap);
            event_results[event_count++] = opcode == 2 ? heap.values[index] : extract_at(&heap, index);
        } else {
            event_results[event_count++] = (int64_t)heap.count;
        }
    }
    int32_t sorted[MAX_HEAP_SIZE];
    for (size_t index = 0; index < heap.count; ++index) sorted[index] = heap.values[index];
    insertion_sort(sorted, heap.count);
    const size_t required = (2 + event_count + heap.count) * 8;
    if (output == NULL || capacity < required) return CAPACITY_RESULT;
    size_t offset = 0;
    write_i64_le(output, offset, (int64_t)event_count); offset += 8;
    for (size_t index = 0; index < event_count; ++index, offset += 8) write_i64_le(output, offset, event_results[index]);
    write_i64_le(output, offset, (int64_t)heap.count); offset += 8;
    for (size_t index = 0; index < heap.count; ++index, offset += 8) write_i64_le(output, offset, sorted[index]);
    return (int64_t)required;
}
