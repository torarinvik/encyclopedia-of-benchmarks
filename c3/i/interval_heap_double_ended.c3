module interval_heap_double_ended;

const usz MAX_INITIAL = 64;
const usz MAX_OPERATIONS = 128;
const usz MAX_KEYS = MAX_INITIAL + MAX_OPERATIONS;
const usz MAX_INPUT = MAX_INITIAL + 2 + 2 * MAX_OPERATIONS;

fn usz high_index(i32* heap, usz count, usz node) {
    usz high = 2 * node + 1;
    return high < count ? high : 2 * node;
}

fn void sift_up_low(i32* heap, usz start) {
    usz node = start;
    while (node > 0) {
        usz parent = (node - 1) / 2;
        usz low = 2 * node;
        usz parent_low = 2 * parent;
        if (heap[low] >= heap[parent_low]) return;
        i32 temporary = heap[low]; heap[low] = heap[parent_low]; heap[parent_low] = temporary;
        node = parent;
    }
}

fn void sift_up_high(i32* heap, usz count, usz start) {
    usz node = start;
    while (node > 0) {
        usz parent = (node - 1) / 2;
        usz high = high_index(heap, count, node);
        usz parent_high = high_index(heap, count, parent);
        if (heap[high] <= heap[parent_high]) return;
        i32 temporary = heap[high]; heap[high] = heap[parent_high]; heap[parent_high] = temporary;
        node = parent;
    }
}

fn void insert_key(i32* heap, usz* count, i32 value) {
    usz key_index = *count;
    heap[key_index] = value;
    *count += 1;
    usz node = key_index / 2;
    if ((key_index & 1) != 0 && heap[key_index] < heap[key_index - 1]) {
        i32 temporary = heap[key_index]; heap[key_index] = heap[key_index - 1]; heap[key_index - 1] = temporary;
    }
    sift_up_low(heap, node);
    sift_up_high(heap, *count, node);
}

fn i32 extract_min(i32* heap, usz* count) {
    i32 result = heap[0];
    *count -= 1;
    i32 last = heap[*count];
    if (*count == 0) return result;
    heap[0] = last;
    usz node = 0;
    while (true) {
        usz left = 2 * node + 1;
        if (2 * left >= *count) return result;
        usz right = left + 1;
        usz child = left;
        if (2 * right < *count && heap[2 * right] < heap[2 * left]) child = right;
        usz node_low = 2 * node;
        usz child_low = 2 * child;
        if (heap[child_low] >= heap[node_low]) return result;
        i32 temporary = heap[node_low]; heap[node_low] = heap[child_low]; heap[child_low] = temporary;
        usz child_high = high_index(heap, *count, child);
        if (heap[child_high] < heap[child_low]) {
            i32 pair_temporary = heap[child_high]; heap[child_high] = heap[child_low]; heap[child_low] = pair_temporary;
        }
        node = child;
    }
}

fn i32 extract_max(i32* heap, usz* count) {
    if (*count <= 2) { *count -= 1; return heap[*count]; }
    i32 result = heap[1];
    *count -= 1;
    heap[1] = heap[*count];
    usz node = 0;
    while (true) {
        usz left = 2 * node + 1;
        if (2 * left >= *count) return result;
        usz right = left + 1;
        usz child = left;
        if (2 * right < *count && heap[high_index(heap, *count, left)] < heap[high_index(heap, *count, right)]) child = right;
        usz node_high = high_index(heap, *count, node);
        usz child_high = high_index(heap, *count, child);
        if (heap[node_high] >= heap[child_high]) return result;
        i32 temporary = heap[node_high]; heap[node_high] = heap[child_high]; heap[child_high] = temporary;
        usz child_low = 2 * child;
        if (heap[child_high] < heap[child_low]) {
            i32 pair_temporary = heap[child_high]; heap[child_high] = heap[child_low]; heap[child_low] = pair_temporary;
        }
        node = child;
    }
}

fn void write_i64(char* output, usz offset, long value) {
    ulong bits = (ulong)value;
    for (usz byte = 0; byte < 8; byte++) { output[offset + byte] = (char)(bits & 255); bits >>= 8; }
}

fn void sort_i32(i32* values, usz count) {
    for (usz index = 1; index < count; index++) {
        i32 value = values[index];
        usz position = index;
        while (position > 0 && values[position - 1] > value) { values[position] = values[position - 1]; position -= 1; }
        values[position] = value;
    }
}

fn long interval_heap_double_ended(long* input, usz length, char* output, usz capacity)
    @export("interval_heap_double_ended") {
    if (input == null || length < 2 || length > MAX_INPUT) return -1;
    if (input[0] < 0 || input[0] > (long)MAX_INITIAL) return -1;
    usz initial_count = (usz)input[0];
    if (length < initial_count + 2) return -1;
    if (input[initial_count + 1] < 0 || input[initial_count + 1] > (long)MAX_OPERATIONS) return -1;
    usz operation_count = (usz)input[initial_count + 1];
    if (length != initial_count + 2 + 2 * operation_count) return -1;
    for (usz index = 0; index < initial_count; index++)
        if (input[index + 1] < -2147483648 || input[index + 1] > 2147483647) return -1;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[initial_count + 2 + 2 * op];
        long argument = input[initial_count + 3 + 2 * op];
        if (opcode < 0 || opcode > 5) return -1;
        if (opcode == 0) { if (argument < -2147483648 || argument > 2147483647) return -1; }
        else if (argument != 0) return -1;
    }

    i32[MAX_KEYS] heap;
    usz count = 0;
    for (usz index = 0; index < initial_count; index++) insert_key(&heap[0], &count, (i32)input[index + 1]);
    long[MAX_OPERATIONS] events;
    usz event_count = 0;
    for (usz op = 0; op < operation_count; op++) {
        long opcode = input[initial_count + 2 + 2 * op];
        i32 argument = (i32)input[initial_count + 3 + 2 * op];
        if (opcode == 0) insert_key(&heap[0], &count, argument);
        else if (opcode == 1) { if (count == 0) return -1; events[event_count] = heap[0]; event_count += 1; }
        else if (opcode == 2) { if (count == 0) return -1; events[event_count] = heap[high_index(&heap[0], count, 0)]; event_count += 1; }
        else if (opcode == 3) { if (count == 0) return -1; events[event_count] = extract_min(&heap[0], &count); event_count += 1; }
        else if (opcode == 4) { if (count == 0) return -1; events[event_count] = extract_max(&heap[0], &count); event_count += 1; }
        else { events[event_count] = (long)count; event_count += 1; }
    }
    i32[MAX_KEYS] sorted;
    for (usz index = 0; index < count; index++) sorted[index] = heap[index];
    sort_i32(&sorted[0], count);
    usz required = (2 + event_count + count) * 8;
    if (output == null || capacity < required) return -2;
    usz offset = 0;
    write_i64(output, offset, (long)event_count); offset += 8;
    for (usz index = 0; index < event_count; index++) { write_i64(output, offset, events[index]); offset += 8; }
    write_i64(output, offset, (long)count); offset += 8;
    for (usz index = 0; index < count; index++) { write_i64(output, offset, (long)sorted[index]); offset += 8; }
    return (long)required;
}
