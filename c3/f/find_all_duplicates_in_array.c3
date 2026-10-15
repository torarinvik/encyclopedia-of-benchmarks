module find_all_duplicates;

const usz MAX_LENGTH = 100000;
extern fn void* malloc(usz size);
extern fn void free(void* pointer);

fn void sift_down(int* values, usz root_value, usz end) {
    usz root = root_value;
    while (root * 2 + 1 < end) {
        usz child = root * 2 + 1;
        if (child + 1 < end && values[child] < values[child + 1]) child++;
        if (values[root] >= values[child]) break;
        int temporary = values[root];
        values[root] = values[child];
        values[child] = temporary;
        root = child;
    }
}

fn void heap_sort(int* values, usz length) {
    usz start = length / 2;
    while (start > 0) {
        start--;
        sift_down(values, start, length);
    }
    usz end = length;
    while (end > 1) {
        end--;
        int temporary = values[0];
        values[0] = values[end];
        values[end] = temporary;
        sift_down(values, 0, end);
    }
}

// Sort a bounded copy and emit sorted duplicate values as little-endian i32s.
fn long find_all_duplicates_in_array(long* values, usz length, char* output,
                                     usz output_capacity)
        @export("find_all_duplicates_in_array") {
    if (length > MAX_LENGTH || (length != 0 && values == null)) return -1;
    if (length == 0) return 0;

    for (usz index = 0; index < length; index++) {
        if (values[index] < 1 || values[index] > (long)length) return -1;
    }
    int* sorted = (int*)malloc(length * 4);
    if (sorted == null) return -3;
    defer free(sorted);
    for (usz index = 0; index < length; index++) sorted[index] = (int)values[index];
    heap_sort(sorted, length);

    usz duplicate_count = 0;
    for (usz index = 0; index < length;) {
        usz end = index + 1;
        while (end < length && sorted[end] == sorted[index]) end++;
        usz frequency = end - index;
        if (frequency > 2) return -1;
        if (frequency == 2) duplicate_count++;
        index = end;
    }
    usz output_bytes = duplicate_count * 4;
    if (output_capacity < output_bytes || (output_bytes != 0 && output == null)) return -2;
    usz destination = 0;
    for (usz index = 0; index < length;) {
        usz end = index + 1;
        while (end < length && sorted[end] == sorted[index]) end++;
        if (end - index == 2) {
            uint value = (uint)sorted[index];
            for (usz byte = 0; byte < 4; byte++) {
                output[destination * 4 + byte] = (char)((value >> (byte * 8)) & 255);
            }
            destination++;
        }
        index = end;
    }
    return (long)duplicate_count;
}
