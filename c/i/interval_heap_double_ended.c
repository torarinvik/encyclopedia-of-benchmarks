#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#define IH_MAX_INITIAL 64
#define IH_MAX_OPERATIONS 128
#define IH_MAX_KEYS (IH_MAX_INITIAL + IH_MAX_OPERATIONS)
#define IH_MAX_INPUT (IH_MAX_INITIAL + 2 + 2 * IH_MAX_OPERATIONS)

typedef struct {
    int32_t keys[IH_MAX_KEYS];
    size_t count;
} IntervalHeap;

static size_t high_index(const IntervalHeap *heap, size_t node) {
    const size_t high = 2 * node + 1;
    return high < heap->count ? high : 2 * node;
}

static void sift_up_low(IntervalHeap *heap, size_t node) {
    while (node > 0) {
        const size_t parent = (node - 1) / 2;
        const size_t low = 2 * node;
        const size_t parent_low = 2 * parent;
        if (heap->keys[low] >= heap->keys[parent_low]) return;
        const int32_t temp = heap->keys[low];
        heap->keys[low] = heap->keys[parent_low];
        heap->keys[parent_low] = temp;
        node = parent;
    }
}

static void sift_up_high(IntervalHeap *heap, size_t node) {
    while (node > 0) {
        const size_t parent = (node - 1) / 2;
        const size_t high = high_index(heap, node);
        const size_t parent_high = high_index(heap, parent);
        if (heap->keys[high] <= heap->keys[parent_high]) return;
        const int32_t temp = heap->keys[high];
        heap->keys[high] = heap->keys[parent_high];
        heap->keys[parent_high] = temp;
        node = parent;
    }
}

static void insert_key(IntervalHeap *heap, int32_t value) {
    const size_t key_index = heap->count++;
    heap->keys[key_index] = value;
    const size_t node = key_index / 2;
    if ((key_index & 1u) != 0 && heap->keys[key_index] < heap->keys[key_index - 1]) {
        const int32_t temp = heap->keys[key_index];
        heap->keys[key_index] = heap->keys[key_index - 1];
        heap->keys[key_index - 1] = temp;
    }
    sift_up_low(heap, node);
    sift_up_high(heap, node);
}

static int32_t extract_min(IntervalHeap *heap) {
    const int32_t result = heap->keys[0];
    const int32_t last = heap->keys[--heap->count];
    if (heap->count == 0) return result;
    heap->keys[0] = last;
    size_t node = 0;
    for (;;) {
        const size_t left = 2 * node + 1;
        if (2 * left >= heap->count) return result;
        const size_t right = left + 1;
        size_t child = left;
        if (2 * right < heap->count && heap->keys[2 * right] < heap->keys[2 * left]) child = right;
        const size_t node_low = 2 * node;
        const size_t child_low = 2 * child;
        if (heap->keys[child_low] >= heap->keys[node_low]) return result;
        const int32_t temp = heap->keys[node_low];
        heap->keys[node_low] = heap->keys[child_low];
        heap->keys[child_low] = temp;
        const size_t child_high = high_index(heap, child);
        if (heap->keys[child_high] < heap->keys[child_low]) {
            const int32_t pair_temp = heap->keys[child_high];
            heap->keys[child_high] = heap->keys[child_low];
            heap->keys[child_low] = pair_temp;
        }
        node = child;
    }
}

static int32_t extract_max(IntervalHeap *heap) {
    if (heap->count <= 2) return heap->keys[--heap->count];
    const int32_t result = heap->keys[1];
    heap->keys[1] = heap->keys[--heap->count];
    size_t node = 0;
    for (;;) {
        const size_t left = 2 * node + 1;
        if (2 * left >= heap->count) return result;
        const size_t right = left + 1;
        size_t child = left;
        if (2 * right < heap->count && heap->keys[high_index(heap, left)] < heap->keys[high_index(heap, right)]) child = right;
        const size_t node_high = high_index(heap, node);
        const size_t child_high = high_index(heap, child);
        if (heap->keys[node_high] >= heap->keys[child_high]) return result;
        const int32_t temp = heap->keys[node_high];
        heap->keys[node_high] = heap->keys[child_high];
        heap->keys[child_high] = temp;
        const size_t child_low = 2 * child;
        if (heap->keys[child_high] < heap->keys[child_low]) {
            const int32_t pair_temp = heap->keys[child_high];
            heap->keys[child_high] = heap->keys[child_low];
            heap->keys[child_low] = pair_temp;
        }
        node = child;
    }
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value) {
    const uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte) output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

static void sort_i32(int32_t *values, size_t count) {
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

int64_t interval_heap_double_ended(const int64_t *input, size_t length, uint8_t *output, size_t capacity) {
    if (input == NULL || length < 2 || length > IH_MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > IH_MAX_INITIAL) return -1;
    const size_t initial_count = (size_t)input[0];
    if (length < initial_count + 2) return -1;
    if (input[initial_count + 1] < 0 || input[initial_count + 1] > IH_MAX_OPERATIONS) return -1;
    const size_t operation_count = (size_t)input[initial_count + 1];
    if (length != initial_count + 2 + 2 * operation_count) return -1;
    for (size_t index = 0; index < initial_count; ++index)
        if (input[index + 1] < INT32_MIN || input[index + 1] > INT32_MAX) return -1;
    for (size_t op = 0; op < operation_count; ++op) {
        const int64_t opcode = input[initial_count + 2 + 2 * op];
        const int64_t argument = input[initial_count + 3 + 2 * op];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX) return -1;
        } else if (argument != 0) return -1;
    }

    IntervalHeap heap = { .count = 0 };
    for (size_t index = 0; index < initial_count; ++index) insert_key(&heap, (int32_t)input[index + 1]);
    int64_t events[IH_MAX_OPERATIONS];
    size_t event_count = 0;
    for (size_t op = 0; op < operation_count; ++op) {
        const int64_t opcode = input[initial_count + 2 + 2 * op];
        const int32_t argument = (int32_t)input[initial_count + 3 + 2 * op];
        if (opcode == 0) insert_key(&heap, argument);
        else if (opcode == 1) {
            if (heap.count == 0) return -1;
            events[event_count++] = heap.keys[0];
        } else if (opcode == 2) {
            if (heap.count == 0) return -1;
            events[event_count++] = heap.keys[high_index(&heap, 0)];
        } else if (opcode == 3) {
            if (heap.count == 0) return -1;
            events[event_count++] = extract_min(&heap);
        } else if (opcode == 4) {
            if (heap.count == 0) return -1;
            events[event_count++] = extract_max(&heap);
        } else events[event_count++] = (int64_t)heap.count;
    }
    int32_t sorted[IH_MAX_KEYS];
    for (size_t index = 0; index < heap.count; ++index) sorted[index] = heap.keys[index];
    sort_i32(sorted, heap.count);
    const size_t required = (2 + event_count + heap.count) * 8;
    if (output == NULL || capacity < required) return -2;
    size_t offset = 0;
    write_i64_le(output, offset, (int64_t)event_count); offset += 8;
    for (size_t index = 0; index < event_count; ++index, offset += 8) write_i64_le(output, offset, events[index]);
    write_i64_le(output, offset, (int64_t)heap.count); offset += 8;
    for (size_t index = 0; index < heap.count; ++index, offset += 8) write_i64_le(output, offset, sorted[index]);
    return (int64_t)required;
}
