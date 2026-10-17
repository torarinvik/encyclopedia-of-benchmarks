#include <stddef.h>
#include <stdint.h>

#define MAX_LISTS 16
#define MAX_TOTAL_NODES 128
#define MAX_INPUT_LENGTH (1 + MAX_LISTS + MAX_TOTAL_NODES)
#define MAX_OUTPUT_BYTES (4 * MAX_TOTAL_NODES)

typedef struct {
    int64_t value;
    size_t list_index;
    size_t node_index;
} HeapNode;

static int node_less(HeapNode left, HeapNode right) {
    if (left.value != right.value) return left.value < right.value;
    if (left.list_index != right.list_index) return left.list_index < right.list_index;
    return left.node_index < right.node_index;
}

static void heap_push(HeapNode *heap, size_t *size, HeapNode node) {
    size_t index = (*size)++;
    while (index > 0) {
        const size_t parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

static HeapNode heap_pop(HeapNode *heap, size_t *size) {
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

static void put_i32_le(uint8_t *output, size_t offset, int64_t value) {
    const uint32_t bits = (uint32_t)value;
    for (size_t byte = 0; byte < 4; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t merge_ksorted_linked_list(const int64_t *input, size_t length,
                                  uint8_t *output, size_t capacity) {
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_LISTS) return -1;
    const size_t list_count = (size_t)input[0];
    size_t starts[MAX_LISTS] = {0}, lengths[MAX_LISTS] = {0};
    size_t position = 1, total_nodes = 0;
    for (size_t list = 0; list < list_count; ++list) {
        if (position >= length) return -1;
        const int64_t declared = input[position++];
        if (declared < 0 || (uint64_t)declared > MAX_TOTAL_NODES - total_nodes) return -1;
        const size_t list_length = (size_t)declared;
        if (list_length > length - position) return -1;
        starts[list] = position;
        lengths[list] = list_length;
        for (size_t node = 0; node < list_length; ++node) {
            const int64_t value = input[position + node];
            if (value < INT32_MIN || value > INT32_MAX ||
                (node > 0 && input[position + node - 1] > value)) return -1;
        }
        position += list_length;
        total_nodes += list_length;
    }
    if (position != length) return -1;

    const size_t output_bytes = 4 * total_nodes;
    if (output == NULL || capacity < output_bytes) return -2;

    HeapNode heap[MAX_LISTS];
    size_t heap_size = 0;
    for (size_t list = 0; list < list_count; ++list) {
        if (lengths[list] > 0)
            heap_push(heap, &heap_size, (HeapNode){input[starts[list]], list, 0});
    }

    uint8_t buffer[MAX_OUTPUT_BYTES];
    size_t written = 0;
    while (heap_size > 0) {
        const HeapNode node = heap_pop(heap, &heap_size);
        put_i32_le(buffer, written, node.value);
        written += 4;
        const size_t next_index = node.node_index + 1;
        if (next_index < lengths[node.list_index]) {
            heap_push(heap, &heap_size, (HeapNode){
                input[starts[node.list_index] + next_index], node.list_index, next_index
            });
        }
    }

    for (size_t index = 0; index < output_bytes; ++index) output[index] = buffer[index];
    return (int64_t)output_bytes;
}
