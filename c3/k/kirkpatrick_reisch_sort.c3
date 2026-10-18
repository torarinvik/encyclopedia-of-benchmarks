module kirkpatrick_reisch_sort;

import "core:c";

const usz MAX_ELEMENTS = 256;
const usz MAX_BLOCKS = 17;
const usz MAX_PARSEABLE_INPUT_LENGTH = 258;
const usz MAX_OUTPUT_BYTES = 2048;

struct HeapNode {
    long value;
    usz block;
    usz offset;
}

fn bool heap_less(HeapNode left, HeapNode right) {
    if (left.value != right.value) return left.value < right.value;
    if (left.block != right.block) return left.block < right.block;
    return left.offset < right.offset;
}

fn void heap_push(HeapNode* heap, usz* length, HeapNode value) {
    usz position = length[0]++;
    while (position > 0) {
        usz parent = (position - 1) / 2;
        if (!heap_less(value, heap[parent])) break;
        heap[position] = heap[parent];
        position = parent;
    }
    heap[position] = value;
}

fn HeapNode heap_pop(HeapNode* heap, usz* length) {
    HeapNode minimum = heap[0];
    HeapNode last = heap[--length[0]];
    if (length[0] == 0) return minimum;
    usz position = 0;
    while (position * 2 + 1 < length[0]) {
        usz child = position * 2 + 1;
        if (child + 1 < length[0] && heap_less(heap[child + 1], heap[child])) child += 1;
        if (!heap_less(heap[child], last)) break;
        heap[position] = heap[child];
        position = child;
    }
    heap[position] = last;
    return minimum;
}

fn void write_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long kirkpatrick_reisch_sort(long* input, usz input_length, char* output, usz capacity)
    @export("kirkpatrick_reisch_sort") {
    if (input == null || input_length < 1 || input_length > MAX_PARSEABLE_INPUT_LENGTH) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_ELEMENTS) return -1;
    usz count = (usz)input[0];
    if (input_length != count + 1) return -1;

    long[MAX_ELEMENTS] blocks;
    for (usz index = 0; index < count; index += 1) blocks[index] = input[index + 1];
    usz[MAX_BLOCKS] starts;
    usz[MAX_BLOCKS] lengths;
    usz block_count = 0;
    usz block_size = 1;
    if (count > 1) {
        while ((block_size + 1) * (block_size + 1) <= count) block_size += 1;
        for (usz start = 0; start < count; start += block_size) {
            usz length = count - start < block_size ? count - start : block_size;
            starts[block_count] = start;
            lengths[block_count] = length;
            block_count += 1;
            for (usz index = 1; index < length; index += 1) {
                long value = blocks[start + index];
                usz position = index;
                while (position > 0 && blocks[start + position - 1] > value) {
                    blocks[start + position] = blocks[start + position - 1];
                    position -= 1;
                }
                blocks[start + position] = value;
            }
        }
    } else if (count == 1) {
        starts[0] = 0;
        lengths[0] = 1;
        block_count = 1;
    }

    long[MAX_ELEMENTS] sorted;
    usz sorted_count = 0;
    HeapNode[MAX_BLOCKS] heap;
    usz heap_length = 0;
    for (usz block = 0; block < block_count; block += 1)
        heap_push(&heap[0], &heap_length, {blocks[starts[block]], block, 0});
    while (heap_length > 0) {
        HeapNode current = heap_pop(&heap[0], &heap_length);
        sorted[sorted_count++] = current.value;
        usz next = current.offset + 1;
        if (next < lengths[current.block])
            heap_push(&heap[0], &heap_length, {blocks[starts[current.block] + next], current.block, next});
    }

    usz output_bytes = sorted_count * 8;
    if (output_bytes > MAX_OUTPUT_BYTES) return -1;
    if (output == null || capacity < output_bytes) return -2;
    for (usz index = 0; index < sorted_count; index += 1)
        write_i64_le(output, index * 8, sorted[index]);
    return (long)output_bytes;
}
