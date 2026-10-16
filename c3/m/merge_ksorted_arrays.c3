module merge_ksorted_arrays;

const int MAX_ARRAYS = 16;
const usz MAX_TOTAL_VALUES = 128;
const usz MAX_PARSEABLE_LENGTH = 146;
const long MIN_VALUE = -1000000;
const long MAX_VALUE = 1000000;
const long CHECKSUM_OFFSET = 1000001;

struct HeapNode { long value; usz array_index; usz element_index; }

fn bool node_less(HeapNode left, HeapNode right) {
    if (left.value != right.value) return left.value < right.value;
    if (left.array_index != right.array_index) return left.array_index < right.array_index;
    return left.element_index < right.element_index;
}

fn void heap_push(HeapNode* heap, usz* size, HeapNode node) {
    usz index = *size;
    (*size)++;
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
    (*size)--;
    HeapNode last = heap[*size];
    if (*size > 0) {
        usz index = 0;
        while (index < *size / 2) {
            usz child = 2 * index + 1;
            if (child + 1 < *size && node_less(heap[child + 1], heap[child])) child++;
            if (!node_less(heap[child], last)) break;
            heap[index] = heap[child];
            index = child;
        }
        heap[index] = last;
    }
    return result;
}

fn long merge_ksorted_arrays(long* values, usz length) @export("merge_ksorted_arrays") {
    if (values == null || length < 1 || length > MAX_PARSEABLE_LENGTH) return -1;
    if (values[0] < 1 || values[0] > (long)MAX_ARRAYS) return -1;
    usz array_count = values[0].usz();
    usz[MAX_ARRAYS] starts;
    usz[MAX_ARRAYS] lengths;
    usz position = 1;
    usz total_values = 0;
    for (usz array = 0; array < array_count; array++) {
        if (position >= length) return -1;
        long declared = values[position++];
        if (declared < 0 || declared > (long)(MAX_TOTAL_VALUES - total_values)) return -1;
        usz array_length = declared.usz();
        if (array_length > length - position) return -1;
        starts[array] = position;
        lengths[array] = array_length;
        for (usz index = 0; index < array_length; index++) {
            long value = values[position + index];
            if (value < MIN_VALUE || value > MAX_VALUE ||
                (index > 0 && values[position + index - 1] > value)) return -1;
        }
        position += array_length;
        total_values += array_length;
    }
    if (position != length) return -1;

    HeapNode[MAX_ARRAYS] heap;
    usz heap_size = 0;
    for (usz array = 0; array < array_count; array++) {
        if (lengths[array] > 0) {
            HeapNode node;
            node.value = values[starts[array]];
            node.array_index = array;
            node.element_index = 0;
            heap_push(&heap[0], &heap_size, node);
        }
    }
    long checksum = 0;
    long merged_index = 0;
    while (heap_size > 0) {
        HeapNode node = heap_pop(&heap[0], &heap_size);
        checksum += (merged_index + 1) * (node.value + CHECKSUM_OFFSET);
        merged_index++;
        usz next_index = node.element_index + 1;
        if (next_index < lengths[node.array_index]) {
            HeapNode next_node;
            next_node.value = values[starts[node.array_index] + next_index];
            next_node.array_index = node.array_index;
            next_node.element_index = next_index;
            heap_push(&heap[0], &heap_size, next_node);
        }
    }
    return checksum;
}
