#include <stddef.h>
#include <stdint.h>
#include <limits.h>

#define MAX_OPERATIONS 64
#define MAX_LIVE_VALUES 32
#define MAX_INPUT_LENGTH 130
#define MAX_OUTPUT_VALUES 1024

typedef struct {
    int32_t value;
    int left;
    int right;
    int next_free;
} skew_node;

typedef struct {
    skew_node nodes[MAX_LIVE_VALUES];
    int root;
    int free_head;
    int count;
} skew_heap_state;

static void initialize(skew_heap_state *heap)
{
    heap->root = -1;
    heap->count = 0;
    heap->free_head = 0;
    for (int i = 0; i < MAX_LIVE_VALUES; ++i) {
        heap->nodes[i].left = -1;
        heap->nodes[i].right = -1;
        heap->nodes[i].next_free = i + 1 < MAX_LIVE_VALUES ? i + 1 : -1;
    }
}

static int merge(skew_heap_state *heap, int first, int second)
{
    if (first < 0) return second;
    if (second < 0) return first;
    if (heap->nodes[first].value > heap->nodes[second].value) {
        int temporary = first;
        first = second;
        second = temporary;
    }
    int old_right = heap->nodes[first].right;
    heap->nodes[first].right = heap->nodes[first].left;
    heap->nodes[first].left = merge(heap, old_right, second);
    return first;
}

static int insert(skew_heap_state *heap, int32_t value)
{
    if (heap->free_head < 0) return 0;
    int node = heap->free_head;
    heap->free_head = heap->nodes[node].next_free;
    heap->nodes[node].value = value;
    heap->nodes[node].left = -1;
    heap->nodes[node].right = -1;
    heap->nodes[node].next_free = -1;
    heap->root = merge(heap, heap->root, node);
    ++heap->count;
    return 1;
}

static int32_t pop(skew_heap_state *heap)
{
    int node = heap->root;
    int32_t value = heap->nodes[node].value;
    heap->root = merge(heap, heap->nodes[node].left, heap->nodes[node].right);
    heap->nodes[node].left = -1;
    heap->nodes[node].right = -1;
    heap->nodes[node].next_free = heap->free_head;
    heap->free_head = node;
    --heap->count;
    return value;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (size_t byte = 0; byte < 8; ++byte)
        output[offset + byte] = (uint8_t)(bits >> (8 * byte));
}

int64_t skew_heap(const int64_t *input, size_t length, uint8_t *output, size_t capacity)
{
    if (input == NULL || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_OPERATIONS) return -1;
    size_t operation_count = (size_t)input[0];
    if (length != 1 + 2 * operation_count || length > MAX_INPUT_LENGTH - 1) return -1;

    skew_heap_state heap;
    initialize(&heap);
    int64_t answers[MAX_OUTPUT_VALUES];
    size_t answer_count = 0;
    for (size_t operation = 0; operation < operation_count; ++operation) {
        int64_t opcode = input[1 + 2 * operation];
        int64_t argument = input[2 + 2 * operation];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) {
            if (argument < INT32_MIN || argument > INT32_MAX || heap.count == MAX_LIVE_VALUES)
                return -1;
            if (!insert(&heap, (int32_t)argument)) return -1;
        } else {
            if (argument != 0) return -1;
            if (opcode == 1) {
                if (heap.root < 0) return -1;
                answers[answer_count++] = heap.nodes[heap.root].value;
            } else if (opcode == 2) {
                if (heap.root < 0) return -1;
                answers[answer_count++] = pop(&heap);
            } else if (opcode == 3) {
                int32_t snapshot[MAX_LIVE_VALUES];
                size_t snapshot_count = 0;
                while (heap.root >= 0)
                    snapshot[snapshot_count++] = pop(&heap);
                for (size_t i = 0; i < snapshot_count; ++i) {
                    if (!insert(&heap, snapshot[i])) return -1;
                    answers[answer_count++] = snapshot[i];
                }
            } else if (opcode == 4) {
                initialize(&heap);
            } else {
                answers[answer_count++] = heap.count == 0 ? 1 : 0;
            }
        }
    }

    size_t output_bytes = answer_count * 8;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t i = 0; i < answer_count; ++i)
        write_i64_le(output, 8 * i, answers[i]);
    return (int64_t)output_bytes;
}
