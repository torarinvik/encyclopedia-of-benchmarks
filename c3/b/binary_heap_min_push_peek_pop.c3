module binary_heap_min_push_peek_pop;

fn void sift_down(long* heap, usz count, usz index) {
    while (true) {
        usz smallest = index;
        usz left = index * 2 + 1;
        usz right = left + 1;
        if (left < count && heap[left] < heap[smallest]) smallest = left;
        if (right < count && heap[right] < heap[smallest]) smallest = right;
        if (smallest == index) return;
        long temporary = heap[index]; heap[index] = heap[smallest]; heap[smallest] = temporary;
        index = smallest;
    }
}
fn void store_i64_le(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte += 1) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}
fn long binary_heap_min_push_peek_pop(long* values, usz length, char* output, usz capacity) @export("binary_heap_min_push_peek_pop") {
    if (values == null || length < 2 || length > 257) return -1;
    long raw_count = values[0];
    if (raw_count < 1 || raw_count > 256 || length != (usz)raw_count + 1) return -1;
    usz count = (usz)raw_count;
    long[256] heap;
    for (usz index = 0; index < count; index += 1) {
        long value = values[index + 1];
        if (value < -2147483648 || value > 2147483647) return -1;
        usz position = index;
        heap[position] = value;
        while (position > 0) {
            usz parent = (position - 1) / 2;
            if (heap[parent] <= heap[position]) break;
            long temporary = heap[parent]; heap[parent] = heap[position]; heap[position] = temporary;
            position = parent;
        }
    }
    usz output_bytes = 8 * count;
    if (output == null || capacity < output_bytes) return -2;
    usz remaining = count;
    for (usz index = 0; index < count; index += 1) {
        long minimum = heap[0];
        store_i64_le(output, 8 * index, minimum);
        remaining -= 1;
        if (remaining > 0) { heap[0] = heap[remaining]; sift_down(&heap[0], remaining, 0); }
    }
    return (long)output_bytes;
}
