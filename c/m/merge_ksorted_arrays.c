#include <stddef.h>
#include <stdint.h>

#define MAX_ARRAYS 16
#define MAX_TOTAL_VALUES 128
#define MAX_PARSEABLE_LENGTH (1 + MAX_ARRAYS + MAX_TOTAL_VALUES + 1)
#define MIN_VALUE (-1000000)
#define MAX_VALUE 1000000
#define CHECKSUM_OFFSET 1000001

typedef struct {
    int64_t value;
    size_t array_index;
    size_t element_index;
} HeapNode;

static int node_less(HeapNode left, HeapNode right)
{
    if (left.value != right.value) return left.value < right.value;
    if (left.array_index != right.array_index) return left.array_index < right.array_index;
    return left.element_index < right.element_index;
}

static void heap_push(HeapNode *heap, size_t *size, HeapNode node)
{
    size_t index = (*size)++;
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

static HeapNode heap_pop(HeapNode *heap, size_t *size)
{
    const HeapNode result = heap[0];
    const HeapNode last = heap[--(*size)];
    if (*size > 0) {
        size_t index = 0;
        while (index < *size / 2) {
            size_t child = 2 * index + 1;
            if (child + 1 < *size && node_less(heap[child + 1], heap[child])) ++child;
            if (!node_less(heap[child], last)) break;
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    return result;
}

int64_t merge_ksorted_arrays(const int64_t *values, size_t length)
{
    if (values == NULL || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (values[0] < 1 || values[0] > MAX_ARRAYS) return -1;
    const size_t array_count = (size_t)values[0];
    size_t starts[MAX_ARRAYS], lengths[MAX_ARRAYS];
    size_t position = 1, total_values = 0;
    for (size_t array = 0; array < array_count; ++array) {
        if (position >= length) return -1;
        const int64_t declared = values[position++];
        if (declared < 0 || (uint64_t)declared > MAX_TOTAL_VALUES - total_values) return -1;
        const size_t array_length = (size_t)declared;
        if (array_length > length - position) return -1;
        starts[array] = position;
        lengths[array] = array_length;
        for (size_t index = 0; index < array_length; ++index) {
            const int64_t value = values[position + index];
            if (value < MIN_VALUE || value > MAX_VALUE ||
                (index > 0 && values[position + index - 1] > value)) return -1;
        }
        position += array_length;
        total_values += array_length;
    }
    if (position != length) return -1;

    HeapNode heap[MAX_ARRAYS];
    size_t heap_size = 0;
    for (size_t array = 0; array < array_count; ++array) {
        if (lengths[array] > 0) {
            heap_push(heap, &heap_size, (HeapNode){values[starts[array]], array, 0});
        }
    }
    int64_t checksum = 0, merged_index = 0;
    while (heap_size > 0) {
        const HeapNode node = heap_pop(heap, &heap_size);
        checksum += (merged_index + 1) * (node.value + CHECKSUM_OFFSET);
        ++merged_index;
        const size_t next_index = node.element_index + 1;
        if (next_index < lengths[node.array_index]) {
            heap_push(heap, &heap_size, (HeapNode){
                values[starts[node.array_index] + next_index], node.array_index, next_index
            });
        }
    }
    return checksum;
}
