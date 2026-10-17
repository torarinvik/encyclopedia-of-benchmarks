module priority_queue_sort;

const usz MAX_COUNT = 128;
const usz MAX_INPUT_LENGTH = 130;

fn void heap_push(int* heap, usz* size, int value) {
    usz child = size[0];
    size[0] += 1;
    heap[child] = value;
    while (child > 0) {
        usz parent = (child - 1) / 2;
        if (heap[parent] <= heap[child]) break;
        int temporary = heap[parent];
        heap[parent] = heap[child];
        heap[child] = temporary;
        child = parent;
    }
}

fn int heap_pop(int* heap, usz* size) {
    int minimum = heap[0];
    size[0] -= 1;
    if (size[0] == 0) return minimum;
    heap[0] = heap[size[0]];
    usz parent = 0;
    while (true) {
        usz left = 2 * parent + 1;
        if (left >= size[0]) break;
        usz right = left + 1;
        usz smaller = left;
        if (right < size[0] && heap[right] < heap[left]) smaller = right;
        if (heap[parent] <= heap[smaller]) break;
        int temporary = heap[parent];
        heap[parent] = heap[smaller];
        heap[smaller] = temporary;
        parent = smaller;
    }
    return minimum;
}

fn void write_i32_le(char* output, usz offset, int value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 4; byte++) output[offset + byte] = (char)(bits >> (8 * byte));
}

fn long priority_queue_sort(long* input, usz length, char* output,
                            usz output_capacity) @export("priority_queue_sort") {
    if (input == null || length < 1 || length > MAX_INPUT_LENGTH) return -1;
    long raw_count = input[0];
    if (raw_count < 0 || raw_count > 128 || length != 1 + (usz)raw_count) return -1;
    usz count = (usz)raw_count;
    for (usz index = 0; index < count; index++) {
        long value = input[index + 1];
        if (value < -2147483648L || value > 2147483647L) return -1;
    }
    usz byte_count = 4 * count;
    if (output == null || output_capacity < byte_count) return -2;

    int[MAX_COUNT] heap = {0};
    usz heap_size = 0;
    for (usz index = 0; index < count; index++) heap_push(&heap[0], &heap_size, (int)input[index + 1]);
    for (usz index = 0; index < count; index++)
        write_i32_le(output, 4 * index, heap_pop(&heap[0], &heap_size));
    return (long)byte_count;
}
