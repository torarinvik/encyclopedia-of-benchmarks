module merge_ksorted_linked_list;

const usz MAX_LISTS = 16;
const usz MAX_TOTAL_NODES = 128;
const usz MAX_INPUT_LENGTH = 145;
const usz MAX_OUTPUT_BYTES = 512;

struct HeapNode { long value; usz list_index; usz node_index; }

fn bool node_less(HeapNode left, HeapNode right) {
    if (left.value != right.value) return left.value < right.value;
    if (left.list_index != right.list_index) return left.list_index < right.list_index;
    return left.node_index < right.node_index;
}

fn void heap_push(HeapNode* heap, usz* size, HeapNode node) {
    usz index = *size;
    *size += 1;
    while (index > 0) {
        usz parent = (index - 1) / 2;
        if (!node_less(node, heap[parent])) break;
        heap[index] = heap[parent];
        index = parent;
    }
    heap[index] = node;
}

fn HeapNode heap_pop(HeapNode* heap, usz* size) {
    HeapNode result = heap[0];
    *size -= 1;
    HeapNode last = heap[*size];
    if (*size > 0) {
        usz index = 0;
        while (index < *size / 2) {
            usz child = 2 * index + 1;
            if (child + 1 < *size && node_less(heap[child + 1], heap[child])) child += 1;
            if (!node_less(heap[child], last)) break;
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    return result;
}

fn void put_i32_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte += 1) {
        output[offset + byte] = (char)(bits & 255);
        bits >>= 8;
    }
}

long merge_ksorted_linked_list(long* input, usz length, char* output, usz capacity)
        @export("merge_ksorted_linked_list") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_list_count = input[0];
    if (raw_list_count < 0 || raw_list_count > 16) return -1;
    usz list_count = (usz)raw_list_count;
    usz[16] starts, lengths;
    usz position = 1, total_nodes = 0;
    for (usz list = 0; list < list_count; list += 1) {
        if (position >= length) return -1;
        long declared = input[position++];
        if (declared < 0 || (ulong)declared > MAX_TOTAL_NODES - total_nodes) return -1;
        usz list_length = (usz)declared;
        if (list_length > length - position) return -1;
        starts[list] = position;
        lengths[list] = list_length;
        for (usz node = 0; node < list_length; node += 1) {
            long value = input[position + node];
            if (value < -2147483648 || value > 2147483647 ||
                (node > 0 && input[position + node - 1] > value)) return -1;
        }
        position += list_length;
        total_nodes += list_length;
    }
    if (position != length) return -1;

    usz output_bytes = 4 * total_nodes;
    if (output == null || capacity < output_bytes) return -2;

    HeapNode[16] heap;
    usz heap_size = 0;
    for (usz list = 0; list < list_count; list += 1) {
        if (lengths[list] > 0) {
            HeapNode node;
            node.value = input[starts[list]];
            node.list_index = list;
            node.node_index = 0;
            heap_push(&heap[0], &heap_size, node);
        }
    }

    char[512] buffer;
    usz written = 0;
    while (heap_size > 0) {
        HeapNode node = heap_pop(&heap[0], &heap_size);
        put_i32_le(&buffer[0], written, node.value);
        written += 4;
        usz next_index = node.node_index + 1;
        if (next_index < lengths[node.list_index]) {
            HeapNode next_node;
            next_node.value = input[starts[node.list_index] + next_index];
            next_node.list_index = node.list_index;
            next_node.node_index = next_index;
            heap_push(&heap[0], &heap_size, next_node);
        }
    }

    for (usz index = 0; index < output_bytes; index += 1) output[index] = buffer[index];
    return (long)output_bytes;
}
