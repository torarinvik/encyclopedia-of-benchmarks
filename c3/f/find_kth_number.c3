module find_kth_number;

const long INVALID_RESULT = -9223372036854775807L - 1L;
const usz MAX_VALUES = 1024;

fn long find_kth_number(long* values, usz length) @export("find_kth_number") {
    if (values == null || length < 2 || length > MAX_VALUES + 1) return INVALID_RESULT;
    long k = values[0];
    usz count = length - 1;
    if (k < 1 || k > (long)count) return INVALID_RESULT;
    int[MAX_VALUES] heap;
    for (usz i = 0; i < count; i++) {
        long input = values[i + 1];
        if (input < -2147483648L || input > 2147483647L) return INVALID_RESULT;
        usz index = i;
        heap[index] = (int)input;
        while (index > 0) {
            usz parent = (index - 1) / 2;
            if (heap[parent] >= heap[index]) break;
            int temp = heap[parent]; heap[parent] = heap[index]; heap[index] = temp;
            index = parent;
        }
    }
    usz heap_size = count;
    for (long removed = 1; removed < k; removed++) {
        heap_size--;
        heap[0] = heap[heap_size];
        usz index = 0;
        while (index * 2 + 1 < heap_size) {
            usz child = index * 2 + 1;
            if (child + 1 < heap_size && heap[child + 1] > heap[child]) child++;
            if (heap[index] >= heap[child]) break;
            int temp = heap[index]; heap[index] = heap[child]; heap[child] = temp;
            index = child;
        }
    }
    return heap[0];
}
