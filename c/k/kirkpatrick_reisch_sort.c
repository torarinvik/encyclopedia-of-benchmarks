#include <stddef.h>
#include <stdint.h>

enum { MAX_ELEMENTS = 256, MAX_BLOCKS = 17, MAX_VALID_INPUT_LENGTH = 257,
       MAX_PARSEABLE_INPUT_LENGTH = 258, MAX_OUTPUT_BYTES = 2048 };

typedef struct {
    int64_t value;
    size_t block;
    size_t offset;
} HeapNode;

static int heap_less(HeapNode left, HeapNode right)
{
    if (left.value != right.value) return left.value < right.value;
    if (left.block != right.block) return left.block < right.block;
    return left.offset < right.offset;
}

static void heap_push(HeapNode heap[MAX_BLOCKS], size_t *length, HeapNode value)
{
    size_t position = (*length)++;
    while (position > 0) {
        size_t parent = (position - 1u) / 2u;
        if (!heap_less(value, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}

static HeapNode heap_pop(HeapNode heap[MAX_BLOCKS], size_t *length)
{
    HeapNode minimum = heap[0];
    HeapNode last = heap[--(*length)];
    if (*length == 0) return minimum;
    size_t position = 0;
    while (position * 2u + 1u < *length) {
        size_t child = position * 2u + 1u;
        if (child + 1u < *length && heap_less(heap[child + 1u], heap[child])) ++child;
        if (!heap_less(heap[child], last)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = last;
    return minimum;
}

static void write_i64_le(uint8_t *output, size_t offset, int64_t value)
{
    uint64_t bits = (uint64_t)value;
    for (unsigned int byte = 0; byte < 8u; ++byte) {
        output[offset + byte] = (uint8_t)(bits & UINT64_C(0xff));
        bits >>= 8u;
    }
}

int64_t kirkpatrick_reisch_sort(const int64_t *input, size_t input_length,
                                uint8_t *output, size_t capacity)
{
    if (input == NULL || input_length < 1u || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > MAX_ELEMENTS) return -1;
    size_t count = (size_t)input[0];
    if (input_length != count + 1u) return -1;
    int64_t blocks[MAX_ELEMENTS];
    for (size_t index = 0; index < count; ++index) blocks[index] = input[index + 1u];
    size_t starts[MAX_BLOCKS] = {0};
    size_t lengths[MAX_BLOCKS] = {0};
    size_t block_count = 0;
    size_t block_size = count > 1u ? (size_t)0 : 1u;
    if (count > 1u) {
        while ((block_size + 1u) * (block_size + 1u) <= count) ++block_size;
    }
    if (count > 1u) {
        for (size_t start = 0; start < count; start += block_size) {
            size_t length = count - start < block_size ? count - start : block_size;
            starts[block_count] = start;
            lengths[block_count] = length;
            ++block_count;
            for (size_t index = 1; index < length; ++index) {
                int64_t value = blocks[start + index];
                size_t position = index;
                while (position > 0 && blocks[start + position - 1u] > value) {
                    blocks[start + position] = blocks[start + position - 1u];
                    --position;
                }
                blocks[start + position] = value;
            }
        }
    } else if (count == 1u) {
        starts[0] = 0;
        lengths[0] = 1;
        block_count = 1;
    }

    int64_t sorted[MAX_ELEMENTS];
    size_t sorted_count = 0;
    HeapNode heap[MAX_BLOCKS];
    size_t heap_length = 0;
    for (size_t block = 0; block < block_count; ++block)
        heap_push(heap, &heap_length, (HeapNode){blocks[starts[block]], block, 0});
    while (heap_length > 0) {
        HeapNode current = heap_pop(heap, &heap_length);
        sorted[sorted_count++] = current.value;
        size_t next = current.offset + 1u;
        if (next < lengths[current.block])
            heap_push(heap, &heap_length, (HeapNode){blocks[starts[current.block] + next], current.block, next});
    }

    size_t output_bytes = sorted_count * 8u;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == NULL || capacity < output_bytes) return -2;
    for (size_t index = 0; index < sorted_count; ++index)
        write_i64_le(output, index * 8u, sorted[index]);
    return (int64_t)output_bytes;
}
